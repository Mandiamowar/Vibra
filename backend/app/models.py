from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime

from .database import Base

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, index=True)
    saldo = Column(Float, default=0.0)
    reputacion = Column(Float, default=5.0)
    creado_en = Column(DateTime, default=datetime.utcnow)

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

class NodoGrafo(Base):
    __tablename__ = "nodos_grafo"
    id = Column(Integer, primary_key=True, index=True)
    transaccion_id = Column(Integer, ForeignKey("transacciones.id"))
    hash_nodo = Column(String, unique=True, index=True)
    enlaces_previos = Column(Text)
    timestamp = Column(DateTime, default=datetime.utcnow)

class PrecioHistorial(Base):
    __tablename__ = "precio_historial"
    id = Column(Integer, primary_key=True, index=True)
    precio = Column(Float)
    gini = Column(Float)
    transacciones_24h = Column(Integer)
    timestamp = Column(DateTime, default=datetime.utcnow)# Archivo creado por Vibra Pay
# --- NUEVOS MODELOS PARA FACTURACIÓN ---

class Negocio(Base):
    __tablename__ = "negocios"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), unique=True)  # Un usuario puede ser negocio
    nombre_comercial = Column(String, nullable=False)
    nif = Column(String, nullable=False, unique=True)
    direccion = Column(String)
    email_contacto = Column(String)
    telefono = Column(String)
    serie_factura = Column(String, default="A")
    ultimo_numero = Column(Integer, default=0)
    plan = Column(String, default="gratis")  # gratis, pro, payg
    creado_en = Column(DateTime, default=datetime.utcnow)

    # Relación con usuario (si quieres)
    usuario = relationship("Usuario", back_populates="negocio")

# Añadir relación inversa en Usuario (opcional)
# En la clase Usuario, añade:
# negocio = relationship("Negocio", back_populates="usuario", uselist=False)

class Factura(Base):
    __tablename__ = "facturas"

    id = Column(Integer, primary_key=True, index=True)
    negocio_id = Column(Integer, ForeignKey("negocios.id"))
    cliente_id = Column(Integer, ForeignKey("usuarios.id"))  # El cliente es un usuario
    email_destino = Column(String, nullable=False)
    numero_factura = Column(String, unique=True, nullable=False)
    fecha = Column(String, nullable=False)  # ISO date
    importe = Column(Float, nullable=False)
    concepto = Column(String)
    pdf_path = Column(String)  # Ruta local o URL
    enviado = Column(Integer, default=0)  # 0=no enviado, 1=enviado
    creado_en = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    negocio = relationship("Negocio")
    cliente = relationship("Usuario")