# Archivo creado por Vibra Pay
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Usuario, Transaccion
from ..schemas import TransferenciaRequest, TransferenciaResponse
from ..grafo import GrafoTemporal
from ..poiu import ConsensoPoIU
from ..tokenomics import Tokenomics

router = APIRouter(prefix="/transacciones", tags=["transacciones"])

@router.post("/transferir", response_model=TransferenciaResponse)
def transferir(request: TransferenciaRequest, db: Session = Depends(get_db)):
    if request.monto <= 0:
        raise HTTPException(status_code=400, detail="El monto debe ser mayor que 0")
    emisor = db.query(Usuario).filter(Usuario.id == request.emisor_id).first()
    if not emisor:
        raise HTTPException(status_code=404, detail="Emisor no encontrado")
    if emisor.saldo < request.monto:
        raise HTTPException(status_code=400, detail="Saldo insuficiente")
    receptor = db.query(Usuario).filter(Usuario.id == request.receptor_id).first()
    if not receptor:
        raise HTTPException(status_code=404, detail="Receptor no encontrado")
    
    tx = Transaccion(
        emisor_id=request.emisor_id,
        receptor_id=request.receptor_id,
        monto=request.monto,
        estado="pendiente"
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    
    tokenomics = Tokenomics(db)
    comision = tokenomics.aplicar_comision(tx)
    
    poiu = ConsensoPoIU(db)
    resultado = poiu.validar(tx.id)
    if not resultado["aprobada"]:
        raise HTTPException(status_code=400, detail="Transacción rechazada por los validadores")
    
    monto_neto = request.monto - comision
    emisor.saldo -= request.monto
    receptor.saldo += monto_neto
    db.commit()
    
    grafo = GrafoTemporal(db)
    hash_nodo = grafo.crear_nodo(tx.id)
    nuevo_precio = tokenomics.actualizar_precio()
    
    return TransferenciaResponse(
        transaccion_id=tx.id,
        estado=tx.estado,
        hash_nodo=hash_nodo,
        comision=comision,
        quemado=tx.quemado,
        nuevo_precio=nuevo_precio
    )