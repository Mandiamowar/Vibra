from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from datetime import datetime, date
import os
import shutil
import uuid
from ..database import get_db
from ..models import Usuario, Ticket
from ..schemas import TicketCreate, TicketResponse

router = APIRouter(prefix="/tickets", tags=["tickets"])

# Directorio para almacenar imágenes (Render no mantiene archivos estáticos, mejor usar Supabase Storage)
# Pero para el prototipo, lo guardamos localmente (en producción usaríamos un bucket de Supabase)
UPLOAD_DIR = "uploads/tickets"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/subir", response_model=TicketResponse)
async def subir_ticket(
    fecha: str = Form(...),  # formato YYYY-MM-DD
    importe: float = Form(...),
    proveedor: str = Form(None),
    categoria: str = Form(None),
    usuario_id: int = Form(...),
    foto: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # Verificar que el usuario existe
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(404, "Usuario no encontrado")
    
    # Guardar la imagen
    file_extension = os.path.splitext(foto.filename)[1]
    filename = f"{uuid.uuid4()}{file_extension}"
    filepath = os.path.join(UPLOAD_DIR, filename)
    
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(foto.file, buffer)
    
    # En producción, aquí subirías a Supabase Storage y obtendrías la URL pública
    # Por ahora, devolvemos la ruta local (o podríamos usar la URL pública)
    foto_url = f"/uploads/tickets/{filename}"  # Local
    
    # Calcular mes y año
    fecha_obj = datetime.strptime(fecha, "%Y-%m-%d").date()
    mes = fecha_obj.month
    año = fecha_obj.year
    
    # Crear ticket
    ticket = Ticket(
        usuario_id=usuario_id,
        fecha=fecha_obj,
        importe=importe,
        proveedor=proveedor,
        categoria=categoria,
        foto_url=foto_url,
        mes=mes,
        año=año
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    
    return ticket

@router.get("/mis-tickets/{usuario_id}")
def obtener_tickets_usuario(
    usuario_id: int,
    mes: int | None = None,
    año: int | None = None,
    db: Session = Depends(get_db)
):
    query = db.query(Ticket).filter(Ticket.usuario_id == usuario_id)
    if mes and año:
        query = query.filter(Ticket.mes == mes, Ticket.año == año)
    tickets = query.order_by(Ticket.fecha.desc()).all()
    return tickets

@router.delete("/{ticket_id}")
def eliminar_ticket(ticket_id: int, db: Session = Depends(get_db)):
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(404, "Ticket no encontrado")
    
    # Eliminar el archivo físico si existe
    if ticket.foto_url and os.path.exists(ticket.foto_url.lstrip('/')):
        os.remove(ticket.foto_url.lstrip('/'))
    
    db.delete(ticket)
    db.commit()
    return {"mensaje": "Ticket eliminado correctamente"}