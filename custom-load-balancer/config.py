from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Cluster 1 URLs from environment variable
    cluster1_urls: str = ""
    # Cluster 2 URLs from environment variable  
    cluster2_urls: str = ""
    
    class Config:
        # Load from .env file the environment variable
        # if there is no .env file it also looks at systems env variables
        env_file = ".env"
    
    
    # Parse cluster1 and Cluster2 URLs (they come from env variables) string into list
    def get_cluster1_urls(self) -> List[str]:
     
        if not self.cluster1_urls:
            return []
        return [url.strip() for url in self.cluster1_urls.split(',')]
    
    def get_cluster2_urls(self) -> List[str]:
        
        if not self.cluster2_urls:
            return []
        return [url.strip() for url in self.cluster2_urls.split(',')]

settings = Settings()