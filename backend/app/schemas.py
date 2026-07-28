# Archivo creado por Vibra Pay
from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

# ============================================
# ESQUEMAS DE USUARIO
# ============================================

class UsuarioBase(BaseModel):
    nombre: str

class UsuarioCreate(UsuarioBase):
    password: str | None = None

class UsuarioResponse(UsuarioBase):
    id: int
    saldo: float
    reputacion: float
    creado_en: datetime

    class Config:
        from_attributes = True

class UsuarioUpdate(BaseModel):
    nombre: Optional[str] = None
    password: Optional[str] = None
    nif: Optional[str] = None
    razon_social: Optional[str] = None
    email_factura: Optional[str] = None
    direccion_factura: Optional[str] = None
    telefono: Optional[str] = None

# ============================================
# ESQUEMAS DE LOGIN
# ============================================

class LoginRequest(BaseModel):
    nombre: str
    password: str

class LoginResponse(BaseModel):
    id: int
    nombre: str
    saldo: float
    token: str

# ============================================
# ESQUEMAS DE TRANSFERENCIAS
# ============================================

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

# ============================================
# ESQUEMAS DE PRECIO
# ============================================

class PrecioResponse(BaseModel):
    precio: float
    gini: float
    transacciones_24h: int

# ============================================
# ESQUEMAS DE NEGOCIO
# ============================================

class NegocioBase(BaseModel):
    nombre_comercial: str
    nif: str
    direccion: str | None = None
    email_contacto: str | None = None
    telefono: str | None = None
    serie_factura: str = "A"
    iva: float = 21.0

class NegocioCreate(NegocioBase):
    usuario_id: int

class NegocioUpdate(BaseModel):
    nombre_comercial: Optional[str] = None
    nif: Optional[str] = None
    direccion: Optional[str] = None
    email_contacto: Optional[str] = None
    telefono: Optional[str] = None
    serie_factura: Optional[str] = None
    iva: Optional[float] = None

class NegocioResponse(NegocioBase):
    id: int
    usuario_id: int
    ultimo_numero: int
    plan: str
    creado_en: datetime

    class Config:
        from_attributes = True

# ============================================
# ESQUEMAS DE FACTURA
# ============================================

class FacturaCreate(BaseModel):
    negocio_id: int
    cliente_id: int
    importe: float
    concepto: str
    email_destino: str | None = None

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

# ============================================
# ESQUEMAS DE PAGOS CON CÓDIGO
# ============================================

class PagoGenerarRequest(BaseModel):
    receptor_id: int
    monto: float

class PagoGenerarResponse(BaseModel):
    codigo: str
    monto: float
    expira_en: str

class PagoConfirmarRequest(BaseModel):
    codigo: str
    emisor_id: int

class PagoConfirmarResponse(BaseModel):
    mensaje: str
    monto: float
    emisor: str
    receptor: str
    nuevo_saldo_emisor: float
    nuevo_saldo_receptor: float

# ============================================
# ESQUEMAS DE TICKETS
# ============================================

class TicketCreate(BaseModel):
    usuario_id: int
    fecha: date
    importe: float
    proveedor: str
    categoria: Optional[str] = None
    foto_url: Optional[str] = None
    ocr_data: Optional[dict] = None
    mes: int
    year: int

class TicketResponse(BaseModel):
    id: int
    usuario_id: int
    fecha: date
    importe: float
    proveedor: str
    categoria: Optional[str] = None
    foto_url: Optional[str] = None
    ocr_data: Optional[dict] = None
    mes: int
    year: int
    creado_en: datetime

    class Config:
        from_attributes = True