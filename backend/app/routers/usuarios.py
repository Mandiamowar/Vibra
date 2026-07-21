from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Usuario, Negocio
from ..schemas import UsuarioCreate, UsuarioResponse, LoginRequest, LoginResponse

router = APIRouter(prefix="/usuarios", tags=["usuarios"])

@router.post("/", response_model=UsuarioResponse)
def registrar_usuario(usuario: UsuarioCreate, db: Session = Depends(get_db)):
    existente = db.query(Usuario).filter(Usuario.nombre == usuario.nombre).first()
    if existente:
        raise HTTPException(400, "El usuario ya existe")
    nuevo = Usuario(nombre=usuario.nombre, saldo=1000.0)
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

@router.post("/login", response_model=LoginResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.nombre == data.nombre).first()
    if not usuario:
        raise HTTPException(404, "Usuario no encontrado")
    # En producción usar hash de contraseña
    if usuario.password != data.password:
        raise HTTPException(401, "Contraseña incorrecta")
    return {
        "id": usuario.id,
        "nombre": usuario.nombre,
        "saldo": usuario.saldo,
        "token": str(usuario.id)
    }

# 🔥 ENDPOINT DE BÚSQUEDA (sin email)
@router.get("/buscar/{nombre}")
def buscar_usuario_por_nombre(nombre: str, db: Session = Depends(get_db)):
    usuarios = db.query(Usuario).filter(Usuario.nombre.ilike(f"%{nombre}%")).all()
    if not usuarios:
        raise HTTPException(404, "No se encontraron usuarios")
    # ✅ Solo devolvemos id, nombre y saldo (sin email)
    return [
        {
            "id": u.id,
            "nombre": u.nombre,
            "saldo": u.saldo,
        } for u in usuarios
    ]

@router.get("/{usuario_id}", response_model=UsuarioResponse)
def obtener_usuario(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(404, "Usuario no encontrado")
    return usuario