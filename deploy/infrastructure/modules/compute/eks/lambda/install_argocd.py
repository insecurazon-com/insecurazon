import json
import boto3 # type: ignore
import base64
import subprocess
import os
import tempfile
import yaml # type: ignore
from kubernetes import client, config # type: ignore
from kubernetes.client.rest import ApiException # type: ignore

def get_eks_token(cluster_name, region):
    eks = boto3.client('eks', region_name=region)
    response = eks.get_cluster(name=cluster_name)
    cluster_endpoint = response['cluster']['endpoint']
    cluster_ca = response['cluster']['certificateAuthority']['data']
    
    # Get token using AWS CLI
    cmd = f"aws eks get-token --cluster-name {cluster_name} --region {region}"
    token = subprocess.check_output(cmd, shell=True).decode('utf-8')
    token = json.loads(token)['status']['token']
    
    return cluster_endpoint, cluster_ca, token

def configure_k8s_client(cluster_endpoint, cluster_ca, token):
    configuration = client.Configuration()
    configuration.host = cluster_endpoint
    configuration.verify_ssl = True
    configuration.api_key = {"authorization": f"Bearer {token}"}
    
    # Write CA cert to temp file
    with tempfile.NamedTemporaryFile(delete=False) as ca_file:
        ca_file.write(base64.b64decode(cluster_ca))
        configuration.ssl_ca_cert = ca_file.name
    
    return client.ApiClient(configuration)

def create_argocd_configmap(config):
    configmap = {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {
            "name": "argocd-cm",
            "namespace": config["namespace"]
        },
        "data": {
            "url": f"{'https' if config['server']['secure'] else 'http'}://{config['server']['host']}:{config['server']['port']}"
        }
    }
    return configmap

def create_argocd_rbac_configmap(config):
    if not config["rbac"]["enabled"] or not config["rbac"]["policy_csv"]:
        return None
    
    configmap = {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {
            "name": "argocd-rbac-cm",
            "namespace": config["namespace"]
        },
        "data": {
            "policy.csv": config["rbac"]["policy_csv"]
        }
    }
    return configmap

def create_argocd_notifications_configmap(config):
    if not config["notifications"]["enabled"] or not config["notifications"]["config"]:
        return None
    
    configmap = {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {
            "name": "argocd-notifications-cm",
            "namespace": config["namespace"]
        },
        "data": yaml.safe_load(config["notifications"]["config"])
    }
    return configmap

def create_argocd_application(app_config):
    application = {
        "apiVersion": "argoproj.io/v1alpha1",
        "kind": "Application",
        "metadata": {
            "name": app_config["name"],
            "namespace": app_config["namespace"]
        },
        "spec": {
            "source": {
                "repoURL": app_config["source"]["repo_url"],
                "path": app_config["source"]["path"],
                "targetRevision": app_config["source"]["target_revision"]
            },
            "destination": {
                "server": app_config["destination"]["server"],
                "namespace": app_config["destination"]["namespace"]
            }
        }
    }
    
    if "sync_policy" in app_config:
        application["spec"]["syncPolicy"] = {
            "automated": {
                "prune": app_config["sync_policy"]["automated"]["prune"],
                "selfHeal": app_config["sync_policy"]["automated"]["self_heal"]
            },
            "syncOptions": app_config["sync_policy"]["sync_options"]
        }
    
    return application

def install_argocd(k8s_client, config):
    # Create namespace
    v1 = client.CoreV1Api(k8s_client)
    try:
        v1.create_namespace(client.V1Namespace(metadata=client.V1ObjectMeta(name=config["namespace"])))
    except ApiException as e:
        if e.status != 409:  # 409 means namespace already exists
            raise e

    # Install ArgoCD using kubectl with specific version
    cmd = f"kubectl apply -n {config['namespace']} -f https://raw.githubusercontent.com/argoproj/argo-cd/{config['version']}/manifests/install.yaml"
    subprocess.run(cmd, shell=True, check=True)
    
    # Wait for ArgoCD to be ready
    cmd = f"kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n {config['namespace']}"
    subprocess.run(cmd, shell=True, check=True)
    
    # Apply ArgoCD configuration
    configmap = create_argocd_configmap(config)
    v1.create_namespaced_config_map(
        namespace=config["namespace"],
        body=configmap
    )
    
    # Apply RBAC configuration if enabled
    if config["rbac"]["enabled"] and config["rbac"]["policy_csv"]:
        rbac_configmap = create_argocd_rbac_configmap(config)
        v1.create_namespaced_config_map(
            namespace=config["namespace"],
            body=rbac_configmap
        )
    
    # Apply notifications configuration if enabled
    if config["notifications"]["enabled"] and config["notifications"]["config"]:
        notifications_configmap = create_argocd_notifications_configmap(config)
        v1.create_namespaced_config_map(
            namespace=config["namespace"],
            body=notifications_configmap
        )
    
    # Create applications
    for app_config in config["applications"]:
        application = create_argocd_application(app_config)
        v1.create_namespaced_custom_object(
            group="argoproj.io",
            version="v1alpha1",
            namespace=config["namespace"],
            plural="applications",
            body=application
        )

def lambda_handler(event, context):
    try:
        # Get cluster details from event
        cluster_name = event['cluster_name']
        region = event['region']
        argocd_config = event['argocd_config']
        
        # Get EKS cluster credentials
        cluster_endpoint, cluster_ca, token = get_eks_token(cluster_name, region)
        
        # Configure Kubernetes client
        k8s_client = configure_k8s_client(cluster_endpoint, cluster_ca, token)
        
        # Install ArgoCD with configuration
        install_argocd(k8s_client, argocd_config)
        
        return {
            'statusCode': 200,
            'body': json.dumps('ArgoCD installation completed successfully')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error installing ArgoCD: {str(e)}')
        } 