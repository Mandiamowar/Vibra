# Archivo creado por Vibra Pay
from pydantic import BaseModel
from datetime import datetime

class UsuarioBase(BaseModel):
    nombre: str

class UsuarioCreate(UsuarioBase):
    pass

class UsuarioResponse(UsuarioBase):
    id: int
    saldo: float
    reputacion: float
    creado_en: datetime
    class Config:
        from_attributes = True

class TransferenciaRequest(BaseModel):
    emisor_id: int
    receptor_id: int
    monto: float

class TransferenciaResponse(BaseModel):
    transaccion_id: int
    estado: str
    hash_nodo: str
    comision: float
    quemado: float
    nuevo_precio: float

class PrecioResponse(BaseModel):
    precio: float
    gini: float
    transacciones_24h: int