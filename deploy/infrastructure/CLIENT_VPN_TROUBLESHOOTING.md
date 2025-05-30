# Client VPN Troubleshooting Guide

This document covers common issues encountered when setting up Client VPN with EKS and how our Terraform configuration addresses them automatically.

## 🔧 Issues We Solved

### 1. **CIDR Overlap Problem**
**Issue**: Client VPN CIDR overlapping with authorization rule target networks
**Solution**: Changed default client CIDR to `192.168.100.0/22` and provided clear documentation

### 2. **Security Group Access**
**Issue**: EKS security groups not allowing Client VPN traffic
**Solutions**:
- Added IP-based rules for Client VPN CIDR (`10.200.0.0/16` → EKS security group)
- **NEW**: Automatic security group-to-security group rules via EKS module integration

### 3. **Authorization Rules**
**Issue**: Client VPN authorization rules not properly configured
**Solution**: Automatic creation of authorization rules with proper dependencies

### 4. **Route Table Issues**
**Issue**: Missing return routes from VPC to Client VPN
**Solution**: Proper route management (removed conflicting Transit Gateway routes when in same VPC)

## 🚀 How to Use the EKS Integration

### Automatic Security Group Configuration

The EKS integration is now **fully automatic**! When you enable Client VPN, the EKS module automatically detects it and creates the necessary security group rules.

```hcl
client_vpn_config = {
  enabled = true
  # ... other config ...
  
  # No manual EKS configuration needed!
  # The compute/EKS module automatically detects Client VPN and creates security group rules
}
```

The EKS module automatically:
- Detects if Client VPN is enabled in the network module
- Creates security group rules allowing Client VPN → EKS on port 443
- Uses security group-to-security group references (more secure than IP-based rules)

## 🔍 Manual Troubleshooting Commands

If you encounter issues, use these commands to diagnose:

### Check Client VPN Status
```bash
aws ec2 describe-client-vpn-endpoints --region eu-central-1
```

### Check Authorization Rules
```bash
aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id cvpn-endpoint-xxx --region eu-central-1
```

### Check Security Group Rules
```bash
aws ec2 describe-security-groups --group-ids sg-xxx --region eu-central-1
```

### Check EKS Endpoint Type
```bash
aws eks describe-cluster --name eks-cluster --region eu-central-1 --query 'cluster.resourcesVpcConfig.{EndpointPublicAccess:endpointPublicAccess,EndpointPrivateAccess:endpointPrivateAccess}'
```

### Test Connectivity
```bash
# Test DNS resolution
nslookup YOUR-EKS-ENDPOINT.gr7.eu-central-1.eks.amazonaws.com

# Test direct IP connection
telnet 10.1.23.89 443

# Test kubectl
kubectl get ns
```

## 📋 Common Scenarios

### Same VPC Deployment
- Client VPN and EKS in same VPC
- Uses local VPC routing (no Transit Gateway needed for intra-VPC traffic)
- Requires security group rules between Client VPN and EKS

### Multi-VPC Deployment
- Client VPN in one VPC, EKS in another
- Uses Transit Gateway for routing between VPCs
- Requires both Transit Gateway routes and security group rules

### Private EKS Endpoint
- EKS endpoint only accessible from within VPC
- Requires Client VPN to be in same VPC or connected via Transit Gateway
- Hostname resolution returns private IPs

## 🛡️ Security Best Practices

1. **Use specific CIDR blocks**: Avoid broad ranges like `10.0.0.0/8`
2. **Limit authorization rules**: Only allow access to required networks
3. **Use security group references**: More secure than IP-based rules
4. **Enable split tunneling**: Route only required traffic through VPN
5. **Monitor connections**: Enable Client VPN logging for production

## 🎯 Quick Fix Checklist

If Client VPN can't reach EKS:

- [ ] Check authorization rules include EKS VPC CIDR
- [ ] Verify security group allows Client VPN → EKS on port 443
- [ ] Confirm EKS endpoint type (public vs private)
- [ ] Test DNS resolution of EKS hostname
- [ ] Check route tables for return paths
- [ ] Verify no CIDR overlaps between client and target networks

## 🔄 Traffic Flow Diagram

```
Laptop (OpenVPN Client)
    ↓ [Encrypted VPN Tunnel]
AWS Client VPN Endpoint
    ↓ [VPC Network Association]
VPC Subnet (Client VPN attached)
    ↓ [Security Group Rules]
EKS Private Endpoint
    ↓ [API Response]
Back to Laptop
``` 