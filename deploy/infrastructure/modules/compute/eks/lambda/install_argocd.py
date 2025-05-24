import json
import os
import logging
import base64
import tempfile
from kubernetes import client, utils, config # type: ignore
from kubernetes.client.rest import ApiException # type: ignore
import time

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
if os.environ.get('DEBUG', 'false').lower() == 'true':
    logger.setLevel(logging.DEBUG)

def create_k8s_clients(cluster_endpoint, cluster_ca, cluster_token):
    """
    Create Kubernetes API clients for the EKS cluster using provided cluster details
    
    Args:
        cluster_endpoint: EKS cluster API endpoint
        cluster_ca: EKS cluster CA certificate data (base64 encoded)
        cluster_token: Pre-generated authentication token
        
    Returns:
        Tuple of (CoreV1Api, AppsV1Api) clients
    """
    logger.info("Creating Kubernetes clients")
    
    try:
        # Create configuration
        configuration = client.Configuration()
        configuration.host = cluster_endpoint
        configuration.verify_ssl = True
        
        # Create temporary file for CA certificate
        ca_cert_file = tempfile.NamedTemporaryFile(delete=False)
        ca_cert_file.write(base64.b64decode(cluster_ca))
        ca_cert_file.close()
        configuration.ssl_ca_cert = ca_cert_file.name
        
        # Use the pre-generated token
        configuration.api_key = {"authorization": f"Bearer {cluster_token}"}
        
        # Create API clients
        api_client = client.ApiClient(configuration)
        core_v1 = client.CoreV1Api(api_client)
        apps_v1 = client.AppsV1Api(api_client)
        
        logger.info("Successfully created Kubernetes API clients")
        return core_v1, apps_v1, configuration
    except Exception as e:
        logger.error(f"Failed to create Kubernetes clients: {e}")
        raise

def create_namespace(core_v1, namespace):
    """
    Create Kubernetes namespace
    
    Args:
        core_v1: CoreV1Api client
        namespace: Namespace name
    """
    logger.info(f"Creating namespace '{namespace}'")
    try:
        core_v1.read_namespace(name=namespace)
        logger.info(f"Namespace '{namespace}' already exists")
    except ApiException as e:
        if e.status == 404:
            # Namespace doesn't exist, create it
            ns_manifest = client.V1Namespace(
                metadata=client.V1ObjectMeta(name=namespace)
            )
            core_v1.create_namespace(body=ns_manifest)
            logger.info(f"Namespace '{namespace}' created successfully")
        else:
            logger.error(f"Error checking namespace: {e}")
            raise

def apply_yaml_manifest(configuration, manifest_file_path, namespace):
    """
    Apply YAML manifest from local file
    
    Args:
        configuration: Kubernetes client configuration
        manifest_file_path: Local path to the manifest file
        namespace: Target namespace
    """
    logger.info(f"Applying manifest from {manifest_file_path} to namespace '{namespace}'")
    try:
        # Read the manifest content from local file
        with open(manifest_file_path, 'r') as f:
            yaml_content = f.read()
        
        # Split the YAML content into individual resources
        k8s_client = client.ApiClient(configuration)
        
        # Create temporary file with the manifest content
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file_path = temp_file.name
            temp_file.write(yaml_content)
        
        try:
            # Apply the manifest - load and create/update each resource
            logger.info("Applying manifest resources")
            utils.create_from_yaml(
                k8s_client, 
                yaml_file=temp_file_path,
                namespace=namespace,
                verbose=True
            )
            logger.info("Successfully applied manifest")
        except Exception as e:
            logger.error(f"Error applying manifest: {e}")
            # Continue despite errors, as some resources might fail due to dependencies
            logger.warning("Continuing despite errors applying manifest")
        finally:
            # Clean up the temporary file
            os.unlink(temp_file_path)
    except Exception as e:
        logger.error(f"Failed to apply manifest: {e}")
        raise

def wait_for_deployment(apps_v1, namespace, deployment_name, timeout_seconds=300, check_interval=10):
    """
    Wait for a deployment to be available
    
    Args:
        apps_v1: AppsV1Api client
        namespace: Namespace name
        deployment_name: Deployment name
        timeout_seconds: Maximum time to wait in seconds
        check_interval: Interval between checks in seconds
        
    Returns:
        True if deployment is available, False otherwise
    """
    logger.info(f"Waiting for deployment '{deployment_name}' in namespace '{namespace}' to be available")
    start_time = time.time()
    
    while (time.time() - start_time) < timeout_seconds:
        try:
            deployment = apps_v1.read_namespaced_deployment(
                name=deployment_name,
                namespace=namespace
            )
            
            if deployment.status.available_replicas and deployment.status.available_replicas > 0:
                logger.info(f"Deployment '{deployment_name}' is available")
                return True
                
            logger.info(f"Deployment '{deployment_name}' not yet available, waiting {check_interval} seconds...")
            time.sleep(check_interval)
        except ApiException as e:
            if e.status == 404:
                logger.info(f"Deployment '{deployment_name}' not found, waiting {check_interval} seconds...")
                time.sleep(check_interval)
            else:
                logger.error(f"Error checking deployment: {e}")
                return False
                
    logger.warning(f"Timeout waiting for deployment '{deployment_name}' to be available")
    return False

def apply_custom_config(core_v1, configuration, custom_values, namespace):
    """
    Apply custom ArgoCD configuration
    
    Args:
        core_v1: CoreV1Api client
        configuration: Kubernetes client configuration
        custom_values: Custom configuration values
        namespace: Target namespace
    """
    logger.info("Applying custom ArgoCD configuration")
    try:
        # Create a temporary file with the custom values
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file_path = temp_file.name
            json.dump(custom_values, temp_file)
        
        try:
            # Apply the custom configuration
            k8s_client = client.ApiClient(configuration)
            utils.create_from_yaml(
                k8s_client,
                yaml_file=temp_file_path,
                namespace=namespace,
                verbose=True
            )
            logger.info("Successfully applied custom configuration")
        finally:
            # Clean up the temporary file
            os.unlink(temp_file_path)
    except Exception as e:
        logger.error(f"Failed to apply custom configuration: {e}")
        raise

def install_argocd(cluster_endpoint, cluster_ca, cluster_token, argocd_config=None):
    """
    Install ArgoCD in the EKS cluster using Kubernetes Python client
    
    Args:
        cluster_endpoint: EKS cluster API endpoint
        cluster_ca: EKS cluster CA certificate data
        cluster_token: Pre-generated authentication token
        argocd_config: Optional configuration for ArgoCD installation
    """
    namespace = argocd_config.get('namespace', 'argocd') if argocd_config else 'argocd'
    manifest_file_path = argocd_config.get('manifest_file_path', 'argocd-install.yaml') if argocd_config else 'argocd-install.yaml'
    
    # Create Kubernetes clients
    core_v1, apps_v1, configuration = create_k8s_clients(cluster_endpoint, cluster_ca, cluster_token)
    
    # Create namespace
    create_namespace(core_v1, namespace)
    
    # Apply ArgoCD manifests
    apply_yaml_manifest(configuration, manifest_file_path, namespace)
    
    # Wait for ArgoCD server deployment
    deployment_available = wait_for_deployment(
        apps_v1, 
        namespace, 
        'argocd-server', 
        timeout_seconds=300, 
        check_interval=10
    )
    
    if not deployment_available:
        logger.warning("ArgoCD server deployment did not become available within the timeout period")
    
    # Apply any custom configurations from argocd_config
    if argocd_config and argocd_config.get('custom_values'):
        apply_custom_config(core_v1, configuration, argocd_config['custom_values'], namespace)
    
    logger.info("ArgoCD installation completed")

def lambda_handler(event, context):
    """
    Lambda handler function.
    
    Args:
        event: Lambda event
        context: Lambda context
        
    Returns:
        Dictionary with statusCode and body
    """
    logger.info("Starting ArgoCD installer Lambda function")
    logger.debug(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract configuration from environment variables
        cluster_name = os.environ.get('CLUSTER_NAME')
        cluster_endpoint = os.environ.get('CLUSTER_ENDPOINT')
        cluster_ca = os.environ.get('CLUSTER_CA')
        cluster_token = os.environ.get('CLUSTER_TOKEN')
        argocd_config = event.get('argocd_config', {})
        
        if not cluster_name:
            raise ValueError("Cluster name is required")
        
        if not cluster_endpoint or not cluster_ca or not cluster_token:
            raise ValueError("Cluster endpoint, CA certificate, and authentication token are required")
        
        logger.info(f"Installing ArgoCD to cluster '{cluster_name}'")
        logger.info(f"Cluster endpoint: {cluster_endpoint}")
        
        # Install ArgoCD
        install_argocd(cluster_endpoint, cluster_ca, cluster_token, argocd_config)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'ArgoCD installation completed successfully',
                'cluster': cluster_name
            })
        }
    except Exception as e:
        logger.error(f"Error installing ArgoCD: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Error installing ArgoCD: {str(e)}',
                'error_type': type(e).__name__
            })
        } 