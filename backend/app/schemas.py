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

    # --- ESQUEMAS DE NEGOCIO ---

class NegocioBase(BaseModel):
    nombre_comercial: str
    nif: str
    direccion: str | None = None
    email_contacto: str | None = None
    telefono: str | None = None
    serie_factura: str = "A"

class NegocioCreate(NegocioBase):
    usuario_id: int  # ID del usuario que será el negocio

class NegocioResponse(NegocioBase):
    id: int
    usuario_id: int
    ultimo_numero: int
    plan: str
    creado_en: datetime

    class Config:
        from_attributes = True

# --- ESQUEMAS DE FACTURA ---

class FacturaCreate(BaseModel):
    negocio_id: int
    cliente_id: int
    importe: float
    concepto: str
    email_destino: str | None = None  # Si no se envía, se usa el email del cliente

class FacturaResponse(BaseModel):
    id: int
    numero_factura: str
    pdf_url: str
    enviado: bool
    fecha: str
    importe: float
    concepto: str

    class Config:
        from_attributes = True

class FacturaListResponse(BaseModel):
    id: int
    numero_factura: str
    fecha: str
    importe: float
    concepto: str
    cliente_nombre: str
    enviado: bool

class PagoGenerarRequest(BaseModel):
    emisor_id: int
    receptor_id: int
    monto: float

class PagoGenerarResponse(BaseModel):
    codigo: str
    monto: float
    expira_en: str

class PagoConfirmarRequest(BaseModel):
    codigo: str

class PagoConfirmarResponse(BaseModel):
    mensaje: str
    monto: float
    emisor: str
    receptor: str
    
class LoginRequest(BaseModel):
    nombre: str
    password: str

class LoginResponse(BaseModel):
    id: int
    nombre: str
    saldo: float
    token: str