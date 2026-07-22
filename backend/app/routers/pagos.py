from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random
from decimal import Decimal

from ..database import get_db
from ..models import Usuario, Transaccion, PagoPendiente
from ..schemas import PagoGenerarRequest, PagoGenerarResponse, PagoConfirmarRequest, PagoConfirmarResponse

router = APIRouter(prefix="/pagos", tags=["pagos"])

@router.post("/generar", response_model=PagoGenerarResponse)
def generar_pago(data: PagoGenerarRequest, db: Session = Depends(get_db)):
    # 🔥 Solo necesitamos receptor_id y monto
    receptor = db.query(Usuario).filter(Usuario.id == data.receptor_id).first()
    if not receptor:
        raise HTTPException(404, "Receptor no encontrado")
    # No verificamos saldo del emisor porque aún no se conoce

    # Generar código único
    codigo = None
    while codigo is None:
        nuevo_codigo = f"{random.randint(100000, 999999)}"
        existente = db.query(PagoPendiente).filter(PagoPendiente.codigo == nuevo_codigo).first()
        if not existente:
            codigo = nuevo_codigo

    # 🔥 emisor_id se deja en NULL (se asignará al confirmar)
    pago = PagoPendiente(
        codigo=codigo,
        emisor_id=None,  # ⬅️ Importante: NULL
        receptor_id=data.receptor_id,
        monto=Decimal(str(data.monto)),
        expira_en=datetime.utcnow() + timedelta(minutes=5)
    )
    db.add(pago)
    db.commit()
    db.refresh(pago)

    return {
        "codigo": codigo,
        "monto": data.monto,
        "expira_en": pago.expira_en.isoformat()
    }

class PagoConfirmarRequest(BaseModel):
    codigo: str
    emisor_id: int  # 🔥 Ahora es obligatorio

@router.post("/confirmar", response_model=PagoConfirmarResponse)
def confirmar_pago(data: PagoConfirmarRequest, db: Session = Depends(get_db)):
    pago = db.query(PagoPendiente).filter(
        PagoPendiente.codigo == data.codigo,
        PagoPendiente.estado == "pendiente"
    ).first()
    if not pago:
        raise HTTPException(404, "Código inválido o pago ya procesado")

    if pago.expira_en < datetime.utcnow():
        pago.estado = "expirado"
        db.commit()
        raise HTTPException(400, "El código ha expirado")

    # 🔥 El emisor es quien confirma (pagador)
    emisor = db.query(Usuario).filter(Usuario.id == data.emisor_id).first()
    receptor = db.query(Usuario).filter(Usuario.id == pago.receptor_id).first()
    if not emisor or not receptor:
        raise HTTPException(404, "Usuario no encontrado")

    monto_float = float(pago.monto)
    if emisor.saldo < monto_float:
        pago.estado = "fallido"
        db.commit()
        raise HTTPException(400, "Saldo insuficiente del emisor")

    # Actualizar saldos
    emisor.saldo -= monto_float
    receptor.saldo += monto_float
    pago.estado = "completado"
    pago.emisor_id = emisor.id  # Guardar emisor real

    tx = Transaccion(
        emisor_id=emisor.id,
        receptor_id=receptor.id,
        monto=monto_float,
        estado="confirmada"
    )
    db.add(tx)
    db.commit()

    return {
        "mensaje": "Pago completado",
        "monto": monto_float,
        "emisor": emisor.nombre,
        "receptor": receptor.nombre,
        "nuevo_saldo_emisor": emisor.saldo,
        "nuevo_saldo_receptor": receptor.saldo
    }