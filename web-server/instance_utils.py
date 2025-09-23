from config import settings
from dotenv import load_dotenv

load_dotenv("/home/ubuntu/app/.env")
# Helper function to get the cluster name with the help of settings (env variables)
def get_cluster_name() -> str:
    return settings.cluster_name

# Helper function to get the instance ID with the help of settings (env variables)
def get_instance_id() -> str:
    return settings.instance_id