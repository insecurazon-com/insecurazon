import json
import os
import boto3
import pymongo
import certifi
import ssl
import time
from botocore.exceptions import ClientError

def get_secret(secret_name):
    """Retrieve a secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager')
    try:
        response = client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
    except ClientError as e:
        print(f"Error retrieving secret {secret_name}: {str(e)}")
        raise e
    return None

def get_all_app_user_secrets(prefix, environment):
    """Get all application user secrets based on naming pattern"""
    client = boto3.client('secretsmanager')
    app_users = []
    try:
        # Pattern: documentdb-elastic-app-user-{username}-{environment}
        pattern = f"documentdb-elastic-app-user-"
        response = client.list_secrets(
            Filters=[
                {
                    'Key': 'name',
                    'Values': [f"{pattern}*-{environment}"]
                }
            ]
        )
        
        for secret in response.get('SecretList', []):
            secret_name = secret['Name']
            if pattern in secret_name and secret_name.endswith(f"-{environment}"):
                user_creds = get_secret(secret_name)
                if user_creds:
                    app_users.append(user_creds)
                
        # Handle pagination if needed
        while 'NextToken' in response:
            response = client.list_secrets(
                NextToken=response['NextToken'],
                Filters=[
                    {
                        'Key': 'name',
                        'Values': [f"{pattern}*-{environment}"]
                    }
                ]
            )
            for secret in response.get('SecretList', []):
                secret_name = secret['Name']
                if pattern in secret_name and secret_name.endswith(f"-{environment}"):
                    user_creds = get_secret(secret_name)
                    if user_creds:
                        app_users.append(user_creds)
                    
    except ClientError as e:
        print(f"Error listing secrets: {str(e)}")
        raise e
    
    return app_users

def create_mongodb_user(client, username, password, roles):
    """Create a user in MongoDB/DocumentDB"""
    try:
        # Using command method to create user
        result = client.admin.command(
            "createUser",
            username,
            pwd=password,
            roles=roles
        )
        return result
    except Exception as e:
        if "already exists" in str(e):
            print(f"User {username} already exists. Updating password...")
            try:
                # Update user if it already exists
                result = client.admin.command(
                    "updateUser",
                    username,
                    pwd=password,
                    roles=roles
                )
                return result
            except Exception as update_error:
                print(f"Error updating user {username}: {str(update_error)}")
                raise update_error
        else:
            print(f"Error creating user {username}: {str(e)}")
            raise e

def lambda_handler(event, context):
    """
    Lambda function to create DocumentDB Elastic users
    - Retrieves admin credentials from Secrets Manager
    - Retrieves application user credentials from Secrets Manager
    - Connects to DocumentDB Elastic cluster
    - Creates users with appropriate roles
    """
    # Get environment variables
    cluster_endpoint = os.environ.get('DOCDB_ENDPOINT')
    admin_secret_name = os.environ.get('ADMIN_SECRET_NAME')
    environment = os.environ.get('ENVIRONMENT')
    
    if not cluster_endpoint or not admin_secret_name or not environment:
        return {
            'statusCode': 500,
            'body': json.dumps('Missing required environment variables')
        }
    
    # Allow time for the cluster to be fully available
    time.sleep(5)
    
    try:
        # Get admin credentials
        admin_creds = get_secret(admin_secret_name)
        if not admin_creds:
            return {
                'statusCode': 500,
                'body': json.dumps('Failed to retrieve admin credentials')
            }
        
        admin_username = admin_creds.get('username')
        admin_password = admin_creds.get('password')
        
        # Create connection string
        connection_string = f"mongodb://{admin_username}:{admin_password}@{cluster_endpoint}:27017/?tls=true&tlsCAFile={certifi.where()}&retryWrites=false"
        
        # Connect to DocumentDB
        client = pymongo.MongoClient(connection_string)
        
        # Test connection
        client.admin.command('ismaster')
        
        print("Successfully connected to DocumentDB Elastic cluster")
        
        # Get application user credentials
        app_users = get_all_app_user_secrets("documentdb-elastic-app-user", environment)
        
        created_users = []
        for user in app_users:
            username = user.get('username')
            password = user.get('password')
            
            # Get roles from the secret
            db_roles = user.get('db_roles', [])
            
            # Convert db_roles to the format expected by MongoDB
            roles = []
            if db_roles:
                for role_entry in db_roles:
                    if isinstance(role_entry, dict) and 'db' in role_entry and 'role' in role_entry:
                        roles.append({"role": role_entry.get('role'), "db": role_entry.get('db')})
            
            # If no roles were specified, apply default roles
            if not roles:
                print(f"No roles specified for user {username}, applying default readWrite role")
                roles = [{"role": "readWrite", "db": "admin"}]
            
            # Create the user
            result = create_mongodb_user(client, username, password, roles)
            created_users.append(username)
            print(f"Successfully created user: {username} with roles: {roles}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Successfully created/updated users: {", ".join(created_users)}')
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error creating DocumentDB users: {str(e)}')
        }
    finally:
        try:
            if 'client' in locals():
                client.close()
        except:
            pass 