from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, DECIMAL
from sqlalchemy.orm import relationship
from datetime import datetime, timedelta  # <-- IMPORTAR timedelta
from .database import Base

# ============================================
# MODELO USUARIO (extendido con datos fiscales)
# ============================================
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, index=True)
    password = Column(String, nullable=True)
    saldo = Column(Float, default=0.0)
    reputacion = Column(Float, default=5.0)
    creado_en = Column(DateTime, default=datetime.utcnow)

    # Campos nuevos para facturación B2B
    nif = Column(String, nullable=True)
    razon_social = Column(String, nullable=True)
    email_factura = Column(String, nullable=True)
    direccion_factura = Column(String, nullable=True)
    

    # Relación con Negocio (1 a 1)
    negocio = relationship("Negocio", back_populates="usuario", uselist=False)

    # Relación con Facturas como cliente
    facturas_cliente = relationship("Factura", foreign_keys="Factura.cliente_id", back_populates="cliente")

# ============================================
# MODELO TRANSACCIÓN
# ============================================
class Transaccion(Base):
    __tablename__ = "transacciones"

    id = Column(Integer, primary_key=True, index=True)
    emisor_id = Column(Integer, ForeignKey("usuarios.id"))
    receptor_id = Column(Integer, ForeignKey("usuarios.id"))
    monto = Column(Float)
    comision = Column(Float, default=0.0)
    quemado = Column(Float, default=0.0)
    validadores_votos = Column(Integer, default=0)
    estado = Column(String, default="pendiente")
    creado_en = Column(DateTime, default=datetime.utcnow)

    emisor = relationship("Usuario", foreign_keys=[emisor_id])
    receptor = relationship("Usuario", foreign_keys=[receptor_id])

# ============================================
# MODELO NODO GRAFO
# ============================================
class NodoGrafo(Base):
    __tablename__ = "nodos_grafo"

    id = Column(Integer, primary_key=True, index=True)
    transaccion_id = Column(Integer, ForeignKey("transacciones.id"))
    hash_nodo = Column(String, unique=True, index=True)
    enlaces_previos = Column(Text)
    timestamp = Column(DateTime, default=datetime.utcnow)

# ============================================
# MODELO PRECIO HISTORIAL
# ============================================
class PrecioHistorial(Base):
    __tablename__ = "precio_historial"

    id = Column(Integer, primary_key=True, index=True)
    precio = Column(Float)
    gini = Column(Float)
    transacciones_24h = Column(Integer)
    timestamp = Column(DateTime, default=datetime.utcnow)

# ============================================
# MODELOS NUEVOS PARA FACTURACIÓN
# ============================================

class Negocio(Base):
    __tablename__ = "negocios"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), unique=True)
    nombre_comercial = Column(String, nullable=False)
    nif = Column(String, nullable=False, unique=True)
    direccion = Column(String, nullable=True)
    email_contacto = Column(String, nullable=True)
    telefono = Column(String, nullable=True)
    serie_factura = Column(String, default="A")
    ultimo_numero = Column(Integer, default=0)
    plan = Column(String, default="gratis")
    creado_en = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    usuario = relationship("Usuario", back_populates="negocio")
    facturas = relationship("Factura", back_populates="negocio")

class Factura(Base):
    __tablename__ = "facturas"

    id = Column(Integer, primary_key=True, index=True)
    negocio_id = Column(Integer, ForeignKey("negocios.id"))
    cliente_id = Column(Integer, ForeignKey("usuarios.id"))
    email_destino = Column(String, nullable=False)
    numero_factura = Column(String, unique=True, nullable=False)
    fecha = Column(String, nullable=False)  # ISO date
    importe = Column(DECIMAL(10,2), nullable=False)
    concepto = Column(String, nullable=True)
    pdf_path = Column(String, nullable=True)
    enviado = Column(Integer, default=0)
    creado_en = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    negocio = relationship("Negocio", back_populates="facturas")
    cliente = relationship("Usuario", foreign_keys=[cliente_id], back_populates="facturas_cliente")

# ============================================
# MODELO PARA PAGOS P2P CON CÓDIGO DE 6 DÍGITOS
# ============================================
class PagoPendiente(Base):
    __tablename__ = "pagos_pendientes"

    id = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(6), unique=True, nullable=False)
    emisor_id = Column(Integer, ForeignKey("usuarios.id"))
    receptor_id = Column(Integer, ForeignKey("usuarios.id"))
    monto = Column(DECIMAL(10,2), nullable=False)
    estado = Column(String, default="pendiente")
    creado_en = Column(DateTime, default=datetime.utcnow)
    expira_en = Column(DateTime, default=datetime.utcnow() + timedelta(minutes=5))

    # Relaciones
    emisor = relationship("Usuario", foreign_keys=[emisor_id])
    receptor = relationship("Usuario", foreign_keys=[receptor_id])