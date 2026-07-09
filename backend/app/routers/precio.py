# Archivo creado por Vibra Pay
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import PrecioHistorial
from ..schemas import PrecioResponse
from ..config import settings

router = APIRouter(prefix="/precio", tags=["precio"])

@router.get("/", response_model=PrecioResponse)
def obtener_precio(db: Session = Depends(get_db)):
    ultimo = db.query(PrecioHistorial).order_by(PrecioHistorial.id.desc()).first()
    if not ultimo:
        return PrecioResponse(
            precio=settings.PRECIO_BASE,
            gini=0.0,
            transacciones_24h=0
        )
    return PrecioResponse(
        precio=ultimo.precio,
        gini=ultimo.gini,
        transacciones_24h=ultimo.transacciones_24h
    )