# Archivo creado por Vibra Pay
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from .models import Usuario, Transaccion, PrecioHistorial
from .config import settings

class Tokenomics:
    def __init__(self, db: Session):
        self.db = db
    
    def calcular_gini(self) -> float:
        usuarios = self.db.query(Usuario).filter(Usuario.saldo > 0).all()
        saldos = sorted([u.saldo for u in usuarios])
        if not saldos:
            return 0.0
        n = len(saldos)
        suma_total = sum(saldos)
        if suma_total == 0:
            return 0.0
        suma_ponderada = sum((i + 1) * saldo for i, saldo in enumerate(saldos))
        gini = (2 * suma_ponderada) / (n * suma_total) - (n + 1) / n
        return max(0.0, min(1.0, gini))
    
    def calcular_actividad(self) -> int:
        hace_24h = datetime.utcnow() - timedelta(hours=24)
        return self.db.query(Transaccion).filter(
            Transaccion.creado_en >= hace_24h,
            Transaccion.estado == "confirmada"
        ).count()
    
    def calcular_oferta_total(self) -> float:
        usuarios = self.db.query(Usuario).all()
        saldo_total = sum(u.saldo for u in usuarios)
        quemas = self.db.query(Transaccion).filter(Transaccion.estado == "confirmada").all()
        total_quemado = sum(tx.quemado for tx in quemas)
        return saldo_total + total_quemado
    
    def actualizar_precio(self) -> float:
        gini = self.calcular_gini()
        actividad = self.calcular_actividad()
        oferta = self.calcular_oferta_total()
        factor_distribucion = 1 + (1 - gini) * 0.5
        factor_actividad = 1.0
        if actividad > 100:
            factor_actividad = 1.005
        elif actividad < 10:
            factor_actividad = 0.998
        if oferta > 0:
            factor_oferta = settings.OFERTA_INICIAL / oferta
        else:
            factor_oferta = 1.0
        precio = settings.PRECIO_BASE * factor_distribucion * factor_actividad * factor_oferta
        historial = PrecioHistorial(
            precio=precio,
            gini=gini,
            transacciones_24h=actividad
        )
        self.db.add(historial)
        self.db.commit()
        return precio
    
    def aplicar_comision(self, tx: Transaccion) -> float:
        comision_total = tx.monto * settings.COMISION
        tx.comision = comision_total
        tx.quemado = comision_total * settings.QUEMA_PORCENTAJE
        self.db.commit()
        return comision_total