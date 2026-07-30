from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date
from supabase import create_client
import os
from io import BytesIO

from ..database import get_db
from ..models import Usuario, Negocio, Factura
from ..schemas import FacturaCreate, FacturaResponse, FacturaListResponse
from ..pdf_generator import generar_factura_pdf  # Ajusta si tu función se llama diferente

router = APIRouter(prefix="/facturas", tags=["facturas"])

# 🔥 Inicializar cliente de Supabase con SERVICE_ROLE_KEY (para subir archivos)
supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # ⚠️ Configura esta variable en Render
)

# 🔥 Función auxiliar para generar PDF en bytes (sin guardar en disco)
def generar_factura_pdf_bytes(numero_factura: str, fecha: str, negocio, cliente, importe: float, concepto: str) -> bytes:
    """
    Genera el PDF y devuelve los bytes en lugar de guardarlo en disco.
    """
    # Aquí puedes reutilizar tu función generar_factura_pdf pero modificada para devolver bytes.
    # Si no quieres modificar la original, la copiamos con cambios.
    # Voy a asumir que tienes una función que genera el PDF y la adapto para que devuelva BytesIO.
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import mm
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    import qrcode
    from io import BytesIO as BIO

    def _generar_qr(texto: str):
        qr = qrcode.QRCode(box_size=4, border=1)
        qr.add_data(texto)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buf = BIO()
        img.save(buf, format="PNG")
        buf.seek(0)
        return Image(buf, width=25*mm, height=25*mm)

    buffer = BIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TitleCustom", parent=styles["Title"], fontSize=18, spaceAfter=4)
    normal = styles["Normal"]

    iva_porcentaje = getattr(negocio, 'iva', 21.0)
    neto = importe / (1 + iva_porcentaje / 100)
    iva = importe - neto

    story = []

    # Datos del negocio (emisor)
    story.append(Paragraph(negocio.nombre_comercial, title_style))
    story.append(Paragraph(f"NIF: {negocio.nif}", normal))
    if negocio.direccion:
        story.append(Paragraph(negocio.direccion, normal))
    if negocio.telefono:
        story.append(Paragraph(f"Tel: {negocio.telefono}", normal))
    story.append(Spacer(1, 12*mm))

    # Número y fecha
    story.append(Paragraph(f"<b>Factura nº:</b> {numero_factura}", normal))
    story.append(Paragraph(f"<b>Fecha:</b> {fecha}", normal))
    story.append(Spacer(1, 6*mm))

    # Datos del cliente (receptor)
    story.append(Paragraph(f"<b>Cliente:</b> {cliente.nombre}", normal))
    if hasattr(cliente, 'nif') and cliente.nif:
        story.append(Paragraph(f"<b>NIF/CIF:</b> {cliente.nif}", normal))
    if hasattr(cliente, 'direccion') and cliente.direccion:
        story.append(Paragraph(f"<b>Dirección:</b> {cliente.direccion}", normal))
    story.append(Spacer(1, 10*mm))

    # Tabla de desglose
    data = [
        ["Concepto", "Neto", f"IVA ({iva_porcentaje:.0f}%)", "Total"],
        [concepto, f"{neto:.2f} €", f"{iva:.2f} €", f"{importe:.2f} €"],
    ]
    col_widths = [70*mm, 30*mm, 30*mm, 30*mm]
    table = Table(data, colWidths=col_widths)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#1f2937")),
        ("TEXTCOLOR", (0,0), (-1,0), colors.white),
        ("FONTNAME", (0,0), (-1,0), "Helvetica-Bold"),
        ("ALIGN", (1,0), (-1,-1), "RIGHT"),
        ("GRID", (0,0), (-1,-1), 0.5, colors.grey),
        ("BOTTOMPADDING", (0,0), (-1,-1), 8),
        ("TOPPADDING", (0,0), (-1,-1), 8),
    ]))
    story.append(table)
    story.append(Spacer(1, 6*mm))
    story.append(Paragraph(f"<b>Total: {importe:.2f} €</b>", ParagraphStyle("TotalStyle", parent=normal, fontSize=13, alignment=2)))

    # QR
    story.append(Spacer(1, 10*mm))
    qr_texto = f"FACTURA:{numero_factura}|NIF:{negocio.nif}|IMPORTE:{importe:.2f}"
    story.append(_generar_qr(qr_texto))
    story.append(Paragraph(
        "<font size=8 color=grey>QR de verificación (placeholder — se adaptará a Veri*factu)</font>",
        normal
    ))

    doc.build(story)
    buffer.seek(0)
    return buffer.getvalue()


@router.post("/generar", response_model=FacturaResponse)
def generar_factura(data: FacturaCreate, db: Session = Depends(get_db)):
    # Validar negocio y cliente
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

    # Aquí tu función de envío de email (puedes pasar la URL o el PDF como adjunto)
    enviado = enviar_factura_por_email(email_destino, pdf_url, numero_factura)  # Ajusta tu mailer

    # 🔥 Guardar en base de datos con pdf_url
    factura = Factura(
        negocio_id=negocio.id,
        cliente_id=cliente.id,
        email_destino=email_destino,
        numero_factura=numero_factura,
        fecha=fecha_hoy,
        importe=data.importe,
        concepto=data.concepto,
        pdf_url=pdf_url,  # 🔥 Ahora guardamos la URL
        enviado=1 if enviado else 0,
    )
    db.add(factura)
    db.commit()
    db.refresh(factura)

    return {
        "id": factura.id,
        "numero_factura": numero_factura,
        "pdf_url": pdf_url,  # 🔥 Devolvemos la URL pública
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
    if not factura:
        raise HTTPException(404, "Factura no encontrada")
    if not factura.pdf_url:
        raise HTTPException(404, "La factura no tiene PDF asociado")
    
    # 🔥 Redirigir a la URL pública de Supabase
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url=factura.pdf_url)