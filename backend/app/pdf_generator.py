from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date
from supabase import create_client
import os

from ..database import get_db
from ..models import Usuario, Negocio, Factura
from ..schemas import FacturaCreate, FacturaResponse, FacturaListResponse
from ..pdf_generator import generar_factura_pdf_bytes
from ..mailer import enviar_factura_por_email

router = APIRouter(prefix="/facturas", tags=["facturas"])

# 🔥 Inicializar cliente de Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise Exception("❌ Faltan variables de entorno SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

@router.post("/generar", response_model=FacturaResponse)
def generar_factura(data: FacturaCreate, db: Session = Depends(get_db)):
    # Validar negocio
    negocio = db.query(Negocio).filter(Negocio.id == data.negocio_id).first()
    if not negocio:
        raise HTTPException(404, "Negocio no encontrado")

    # Validar cliente
    cliente = db.query(Usuario).filter(Usuario.id == data.cliente_id).first()
    if not cliente:
        raise HTTPException(404, "Cliente no encontrado")

    # Generar número de factura
    ultimo_numero = negocio.ultimo_numero or 0
    nuevo_numero = ultimo_numero + 1
    negocio.ultimo_numero = nuevo_numero
    db.commit()

    numero_factura = f"{negocio.serie_factura or 'A'}-{nuevo_numero:05d}"
    fecha_hoy = date.today().isoformat()

    # 🔥 Generar PDF en bytes
    pdf_bytes = generar_factura_pdf_bytes(
        numero_factura=numero_factura,
        fecha=fecha_hoy,
        negocio=negocio,
        cliente=cliente,
        importe=data.importe,
        concepto=data.concepto,
    )

    # 🔥 Subir a Supabase Storage
    file_name = f"facturas/{numero_factura}.pdf"
    try:
        supabase.storage.from_('facturas').upload(
            path=file_name,
            file=pdf_bytes,
            file_options={"content-type": "application/pdf"}
        )
    except Exception as e:
        raise HTTPException(500, f"Error al subir el PDF a Storage: {str(e)}")

    # Obtener URL pública
    pdf_url = supabase.storage.from_('facturas').get_public_url(file_name)

    # Enviar email
    email_destino = data.email_destino or cliente.email_factura
    if not email_destino:
        raise HTTPException(400, "El cliente no tiene email de facturación configurado")

    enviado = enviar_factura_por_email(email_destino, pdf_url, numero_factura)

    # 🔥 Guardar en base de datos
    factura = Factura(
        negocio_id=negocio.id,
        cliente_id=cliente.id,
        email_destino=email_destino,
        numero_factura=numero_factura,
        fecha=fecha_hoy,
        importe=data.importe,
        concepto=data.concepto,
        pdf_url=pdf_url,
        enviado=1 if enviado else 0,
    )
    db.add(factura)
    db.commit()
    db.refresh(factura)

    return {
        "id": factura.id,
        "numero_factura": numero_factura,
        "pdf_url": pdf_url,
        "enviado": enviado,
        "fecha": fecha_hoy,
        "importe": data.importe,
        "concepto": data.concepto,
    }

@router.get("/mis-facturas/{usuario_id}", response_model=list[FacturaListResponse])
def listar_mis_facturas(usuario_id: int, db: Session = Depends(get_db)):
    facturas = db.query(Factura).filter(Factura.cliente_id == usuario_id).order_by(Factura.id.desc()).all()
    return [
        {
            "id": f.id,
            "numero_factura": f.numero_factura,
            "fecha": f.fecha,
            "importe": float(f.importe),
            "concepto": f.concepto,
            "cliente_nombre": f.cliente.nombre if f.cliente else "Cliente",
            "enviado": bool(f.enviado),
        }
        for f in facturas
    ]

@router.get("/{factura_id}/pdf")
def descargar_pdf(factura_id: int, db: Session = Depends(get_db)):
    factura = db.query(Factura).filter(Factura.id == factura_id).first()
    if not factura or not factura.pdf_url:
        raise HTTPException(404, "Factura no encontrada o sin PDF asociado")
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url=factura.pdf_url)