# Archivo creado por Vibra Pay
import random
import hashlib
from sqlalchemy.orm import Session

from .models import Transaccion, Usuario
from .config import settings

class ConsensoPoIU:
    def __init__(self, db: Session):
        self.db = db
    
    def _seleccionar_validadores(self, tx_id: int) -> list:
        tx = self.db.query(Transaccion).filter(Transaccion.id == tx_id).first()
        if not tx:
            return []
        usuarios = self.db.query(Usuario).filter(Usuario.reputacion > 0).all()
        if len(usuarios) < settings.NUM_VALIDADORES:
            return list(range(1, settings.NUM_VALIDADORES + 1))
        seed = hashlib.md5(str(tx_id).encode()).hexdigest()
        random.seed(seed)
        return random.sample([u.id for u in usuarios], settings.NUM_VALIDADORES)
    
    def _validar_contexto(self, tx: Transaccion) -> dict:
        emisor = self.db.query(Usuario).filter(Usuario.id == tx.emisor_id).first()
        if not emisor or emisor.saldo < tx.monto:
            return {"valida": False, "razon": "Saldo insuficiente"}
        if tx.monto > 1000000:
            return {"valida": False, "razon": "Monto excesivo (>1M VIBRA)"}
        receptor = self.db.query(Usuario).filter(Usuario.id == tx.receptor_id).first()
        if not receptor:
            return {"valida": False, "razon": "Receptor no existe"}
        return {"valida": True, "razon": "Contexto válido"}
    
    def _validar_utilidad(self, tx: Transaccion) -> dict:
        if tx.monto < 1:
            count = self.db.query(Transaccion).filter(
                Transaccion.emisor_id == tx.emisor_id,
                Transaccion.monto < 1
            ).count()
            if count > 100:
                return {"valida": False, "razon": "Microtransacciones excesivas"}
        receptor = self.db.query(Usuario).filter(Usuario.id == tx.receptor_id).first()
        if receptor and receptor.reputacion < 2:
            return {"valida": False, "razon": "Receptor con baja reputación"}
        return {"valida": True, "razon": "Utilidad válida"}
    
    def validar(self, tx_id: int) -> dict:
        tx = self.db.query(Transaccion).filter(Transaccion.id == tx_id).first()
        if not tx:
            return {"aprobada": False, "razon": "Transacción no encontrada"}
        validadores = self._seleccionar_validadores(tx_id)
        votos_aprueban = 0
        for _ in validadores:
            contexto = self._validar_contexto(tx)
            utilidad = self._validar_utilidad(tx)
            if contexto["valida"] and utilidad["valida"]:
                votos_aprueban += 1
        aprobada = votos_aprueban >= 3
        tx.estado = "confirmada" if aprobada else "rechazada"
        tx.validadores_votos = votos_aprueban
        self.db.commit()
        return {
            "aprobada": aprobada,
            "votos_aprueban": votos_aprueban,
            "total_validadores": len(validadores)
        }