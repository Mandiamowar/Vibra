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
