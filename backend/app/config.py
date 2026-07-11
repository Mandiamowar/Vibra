from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./vibra.db"
    SECRET_KEY: str = "vibra-super-secret-key-cambiar-en-produccion"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    
    NUM_VALIDADORES: int = 5
    COMISION: float = 0.001
    QUEMA_PORCENTAJE: float = 0.4
    VALIDADORES_PORCENTAJE: float = 0.3
    FONDO_PORCENTAJE: float = 0.3
    
    STAKING_APY: float = 0.06
    PRECIO_BASE: float = 0.01
    OFERTA_INICIAL: float = 1_000_000

settings = Settings()
