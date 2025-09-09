from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Cluster name from environment variable
    cluster_name: str
    # Unique instance identifier from environment variable
    instance_id: str
    
    class Config:
        # Load from .env file the environment variable
        # if there is no .env file it also looks at systems env variables
        env_file = ".env"
        
        
# Global settings instance that we will use to get them (the env variables)
settings = Settings()
