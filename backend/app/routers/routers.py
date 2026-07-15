from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Usuario, Negocio
from ..schemas import NegocioCreate, NegocioResponse

router = APIRouter(prefix="/negocios", tags=["negocios"])

@router.post("/registrar", response_model=NegocioResponse)
def registrar_negocio(data: NegocioCreate, db: Session = Depends(get_db)):
    # Verificar que el usuario existe
    usuario = db.query(Usuario).filter(Usuario.id == data.usuario_id).first()
    if not usuario:
        raise HTTPException(404, "Usuario no encontrado")

    # Verificar que el NIF no esté registrado
    existente = db.query(Negocio).filter(Negocio.nif == data.nif).first()
    if existente:
        raise HTTPException(400, "Ya hay un negocio registrado con ese NIF")

    negocio = Negocio(
        usuario_id=data.usuario_id,
        nombre_comercial=data.nombre_comercial,
        nif=data.nif,
        direccion=data.direccion,
        email_contacto=data.email_contacto,
        telefono=data.telefono,
        serie_factura=data.serie_factura,
    )
    db.add(negocio)
    db.commit()
    db.refresh(negocio)
    return negocio

@router.get("/{usuario_id}", response_model=NegocioResponse)
def obtener_negocio(usuario_id: int, db: Session = Depends(get_db)):
    negocio = db.query(Negocio).filter(Negocio.usuario_id == usuario_id).first()
    if not negocio:
        raise HTTPException(404, "Negocio no encontrado")
    return negocio