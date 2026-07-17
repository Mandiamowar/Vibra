from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random

from ..database import get_db
from ..models import Usuario, Transaccion, PagoPendiente
from ..schemas import PagoGenerarRequest, PagoGenerarResponse, PagoConfirmarRequest, PagoConfirmarResponse

router = APIRouter(prefix="/pagos", tags=["pagos"])

@router.post("/generar", response_model=PagoGenerarResponse)
def generar_pago(data: PagoGenerarRequest, db: Session = Depends(get_db)):
    emisor = db.query(Usuario).filter(Usuario.id == data.emisor_id).first()
    if not emisor:
        raise HTTPException(404, "Emisor no encontrado")
    if emisor.saldo < data.monto:
        raise HTTPException(400, "Saldo insuficiente")

    codigo = None
    while codigo is None:
        nuevo_codigo = f"{random.randint(100000, 999999)}"
        existente = db.query(PagoPendiente).filter(PagoPendiente.codigo == nuevo_codigo).first()
        if not existente:
            codigo = nuevo_codigo

    pago = PagoPendiente(
        codigo=codigo,
        emisor_id=data.emisor_id,
        receptor_id=data.receptor_id,
        monto=data.monto,
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

    emisor = db.query(Usuario).filter(Usuario.id == pago.emisor_id).first()
    receptor = db.query(Usuario).filter(Usuario.id == pago.receptor_id).first()
    if not emisor or not receptor:
        raise HTTPException(404, "Usuario no encontrado")

    if emisor.saldo < pago.monto:
        pago.estado = "fallido"
        db.commit()
        raise HTTPException(400, "Saldo insuficiente del emisor")

    # 🔥 ACTUALIZAR SALDOS
    emisor.saldo -= pago.monto
    receptor.saldo += pago.monto
    pago.estado = "completado"

    tx = Transaccion(
        emisor_id=pago.emisor_id,
        receptor_id=pago.receptor_id,
        monto=pago.monto,
        estado="confirmada"
    )
    db.add(tx)
    db.commit()  # <--- ESTO ES CLAVE

    return {
        "mensaje": "Pago completado",
        "monto": pago.monto,
        "emisor": emisor.nombre,
        "receptor": receptor.nombre,
        "nuevo_saldo_emisor": emisor.saldo,
        "nuevo_saldo_receptor": receptor.saldo
    }