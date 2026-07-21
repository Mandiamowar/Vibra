from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date
import os

from ..database import get_db
from ..models import Usuario, Negocio, Factura
from ..schemas import FacturaCreate, FacturaResponse, FacturaListResponse
from ..pdf_generator import generar_factura_pdf
from ..mailer import enviar_factura_por_email

router = APIRouter(prefix="/facturas", tags=["facturas"])

@router.post("/generar", response_model=FacturaResponse)
def generar_factura(data: FacturaCreate, db: Session = Depends(get_db)):
    negocio = db.query(Negocio).filter(Negocio.id == data.negocio_id).first()
    if not negocio:
        raise HTTPException(404, "Negocio no encontrado")

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

    # Generar PDF
    pdf_path = generar_factura_pdf(
        numero_factura=numero_factura,
        fecha=fecha_hoy,
        negocio=negocio,
        cliente=cliente,
        importe=data.importe,
        concepto=data.concepto,
    )

    # Enviar email
    email_destino = data.email_destino or cliente.email
    if not email_destino:
        raise HTTPException(400, "El cliente no tiene email")

    enviado = enviar_factura_por_email(email_destino, pdf_path, numero_factura)

    # 🔥 GUARDAR EN BASE DE DATOS
    factura = Factura(
        negocio_id=negocio.id,
        cliente_id=cliente.id,
        email_destino=email_destino,
        numero_factura=numero_factura,
        fecha=fecha_hoy,
        importe=data.importe,
        concepto=data.concepto,
        pdf_path=pdf_path,
        enviado=1 if enviado else 0,
    )
    db.add(factura)
    db.commit()
    db.refresh(factura)

    return {
        "id": factura.id,
        "numero_factura": numero_factura,
        "pdf_url": f"/facturas/{factura.id}/pdf",
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
    if not factura or not os.path.exists(factura.pdf_path):
        raise HTTPException(404, "Factura no encontrada")
    from fastapi.responses import FileResponse
    return FileResponse(
        factura.pdf_path,
        media_type="application/pdf",
        filename=f"factura_{factura.numero_factura}.pdf"
    )