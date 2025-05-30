#!/bin/bash

set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting OpenVPN Access Server installation..."

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget gnupg2 software-properties-common

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Install OpenVPN Access Server
# Download and install OpenVPN Access Server
cd /tmp

# Detect Ubuntu version for correct repository
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu version: $UBUNTU_CODENAME"

# Add OpenVPN repository with correct codename
wget https://as-repository.openvpn.net/as-repo-public.asc -qO- | apt-key add -
echo "deb http://as-repository.openvpn.net/as/debian $UBUNTU_CODENAME main" > /etc/apt/sources.list.d/openvpn-as-repo.list

apt-get update -y
apt-get install -y openvpn-as

# Get instance metadata
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Initial OpenVPN configuration
echo "Configuring OpenVPN Access Server..."

# Set admin password (change this!)
echo "openvpn:$(openssl rand -base64 12)" | chpasswd

# Configure OpenVPN AS via sacli (Server Admin CLI)
/usr/local/openvpn_as/scripts/sacli --key "host.name" --value "$INSTANCE_IP" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.reroute_gw" --value "true" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_network.0" --value "${vpn_cidr}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.daemon.0.client.network" --value "${vpn_cidr}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.daemon.0.client.netmask_bits" --value "24" ConfigPut

# Allow access from VPN subnet to local networks
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_access" --value "nat" ConfigPut

# Configure DNS
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.dns.0" --value "8.8.8.8" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.dns.1" --value "8.8.4.4" ConfigPut

# Enable authentication via local users (you can change this later)
/usr/local/openvpn_as/scripts/sacli --key "auth.module.type" --value "local" ConfigPut

# Apply configuration
/usr/local/openvpn_as/scripts/sacli start

# Configure iptables for NAT
iptables -t nat -A POSTROUTING -s ${vpn_cidr} -o eth0 -j MASQUERADE
iptables -A FORWARD -s ${vpn_cidr} -j ACCEPT
iptables -A FORWARD -d ${vpn_cidr} -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Install iptables-persistent to restore rules on boot
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y iptables-persistent

# Create a script to restore iptables on boot
cat > /etc/systemd/system/iptables-restore.service << 'EOF'
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable iptables-restore.service

# Create VPN user management script
cat > /usr/local/bin/vpn-user-add << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: vpn-user-add <username>"
    exit 1
fi

USERNAME=$1
PASSWORD=$(openssl rand -base64 12)

# Add user to OpenVPN AS
/usr/local/openvpn_as/scripts/sacli --user "$USERNAME" --key "type" --value "user_connect" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "$USERNAME" --key "conn_group" --value "DEFAULT" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "$USERNAME" --new_pass "$PASSWORD" SetLocalPassword

echo "User '$USERNAME' created with password: $PASSWORD"
echo "User can download config from: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/"
EOF

chmod +x /usr/local/bin/vpn-user-add

# Create VPN user removal script
cat > /usr/local/bin/vpn-user-del << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: vpn-user-del <username>"
    exit 1
fi

USERNAME=$1
/usr/local/openvpn_as/scripts/sacli --user "$USERNAME" UserPropDelAll
echo "User '$USERNAME' deleted"
EOF

chmod +x /usr/local/bin/vpn-user-del

# Install CloudWatch agent (optional)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/openvpnas.log",
                        "log_group_name": "/aws/ec2/vpn-server",
                        "log_stream_name": "openvpn-access-server"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/vpn-server",
                        "log_stream_name": "user-data"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Create motd with instructions
cat > /etc/motd << EOF

=================================
  OpenVPN Access Server Setup
=================================

Server Status: $(systemctl is-active openvpnas)
Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

Admin Interface: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):943/admin
Client Portal: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/

Default admin user: openvpn
Default admin password: Check /var/log/user-data.log

Useful commands:
- Add VPN user: sudo vpn-user-add <username>
- Delete VPN user: sudo vpn-user-del <username>
- Check status: sudo systemctl status openvpnas
- View logs: sudo tail -f /var/log/openvpnas.log

=================================

EOF

# Get and store the admin password for display
ADMIN_PASS=$(grep "openvpn:" /etc/shadow | cut -d: -f2)
echo "==================================" >> /var/log/user-data.log
echo "OpenVPN Access Server installed!" >> /var/log/user-data.log
echo "Admin interface: https://$INSTANCE_IP:943/admin" >> /var/log/user-data.log
echo "Client portal: https://$INSTANCE_IP/" >> /var/log/user-data.log
echo "Admin user: openvpn" >> /var/log/user-data.log
echo "Check the admin password with: sudo grep openvpn /etc/shadow" >> /var/log/user-data.log
echo "==================================" >> /var/log/user-data.log

# Restart services
systemctl restart openvpnas
systemctl enable openvpnas

echo "OpenVPN Access Server installation completed!"
echo "You can now access the admin interface at https://$INSTANCE_IP:943/admin"