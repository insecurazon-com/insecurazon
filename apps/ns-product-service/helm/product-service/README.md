# Product Service Helm Chart

This Helm chart deploys the Insecurazon Product Service on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- MongoDB instance accessible from the cluster

## Getting Started

### Add the repo
```bash
helm repo add insecurazon https://your-repo-url.com
helm repo update
```

### Installing the Chart
```bash
# Basic installation with default values
helm install product-service insecurazon/product-service

# Installation with custom values file
helm install product-service insecurazon/product-service -f values.yaml

# Installation with custom MongoDB URI (directly from command line)
helm install product-service insecurazon/product-service --set mongodb.uri=mongodb://user:password@mongodb-host:27017/insecurazon
```

### Using MongoDB Secret
For production environments, it's recommended to use a Kubernetes Secret for the MongoDB connection string:

1. Create a secret manually:
```bash
kubectl create secret generic mongodb-secret --from-literal=mongodb-uri="mongodb://user:password@mongodb-host:27017/insecurazon"
```

2. Reference it in your values.yaml:
```yaml
mongodb:
  uri: "" # Leave empty to use secretRef
  secretName: mongodb-secret
  secretKey: mongodb-uri
```

## Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `insecurazon/product-service` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port the service forwards to | `8080` |
| `mongodb.uri` | MongoDB connection URI (if not using secret) | `mongodb://mongo:27017/insecurazon` |
| `mongodb.secretName` | Name of the secret containing MongoDB URI | `mongodb-secret` |
| `mongodb.secretKey` | Key in the secret containing MongoDB URI | `mongodb-uri` |
| `resources` | CPU/Memory resource requests/limits | `{}` |

## Connecting from other services

To connect to this service from other applications in the cluster, use:

```
http://product-service.NAMESPACE.svc.cluster.local
```

For the Insecurazon web server, set the environment variable:

```yaml
PRODUCT_SERVICE_URL: http://product-service.NAMESPACE.svc.cluster.local
``` 