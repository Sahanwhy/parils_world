import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_env: str = "development"
    mistral_api_key: str = "mstrl_0DvUOOux3U1u3yOQLP9KAVzyfQhAsfgg_2kQllM"
    mistral_model: str = "open-mistral-7b"
    chroma_persist_dir: str = os.path.join(os.path.dirname(__file__), "chroma_data")
    allowed_origins: str = "*"
    port: int = 8000

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
