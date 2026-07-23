import os
import qrcode
from io import BytesIO
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

OUTPUT_DIR = "facturas_pdf"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def _generar_qr(texto: str) -> Image:
    qr = qrcode.QRCode(box_size=4, border=1)
    qr.add_data(texto)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buf = BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return Image(buf, width=25 * mm, height=25 * mm)

def generar_factura_pdf(numero_factura: str, fecha: str, negocio, cliente, importe_total: float, concepto: str, iva_porcentaje: float = 21.0) -> str:
    """
    Genera un PDF de factura profesional.
    :param importe_total: Importe total con IVA incluido (lo que paga el cliente).
    """
    # Obtener IVA del negocio, si no tiene usar el parámetro de fallback
    iva_porcentaje = getattr(negocio, 'iva', iva_porcentaje)

    # Calcular neto (base imponible) e IVA a partir del total
    # total = neto * (1 + iva/100) -> neto = total / (1 + iva/100)
    neto = importe_total / (1 + iva_porcentaje / 100)
    iva = importe_total - neto

    filename = f"{numero_factura.replace('/', '-')}.pdf"
    path = os.path.join(OUTPUT_DIR, filename)

    doc = SimpleDocTemplate(path, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TitleCustom", parent=styles["Title"], fontSize=18, spaceAfter=4)
    normal = styles["Normal"]
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

    # Tabla de desglose (Concepto, Neto, IVA, Total)
    data = [
        ["Concepto", "Neto", f"IVA ({iva_porcentaje:.0f}%)", "Total"],
        [concepto, f"{neto:.2f} €", f"{iva:.2f} €", f"{importe_total:.2f} €"],
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
    story.append(Paragraph(f"<b>Total: {importe_total:.2f} €</b>", ParagraphStyle("TotalStyle", parent=normal, fontSize=13, alignment=2)))

    # QR (verificación)
    story.append(Spacer(1, 10*mm))
    qr_texto = f"FACTURA:{numero_factura}|NIF:{negocio.nif}|IMPORTE:{importe_total:.2f}"
    story.append(_generar_qr(qr_texto))
    story.append(Paragraph(
        "<font size=8 color=grey>QR de verificación (placeholder — se adaptará a Veri*factu)</font>",
        normal
    ))

    doc.build(story)
    return path