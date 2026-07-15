import os

MODO_SIMULADO = os.getenv("EMAIL_MODE", "simulado") != "produccion"

def enviar_factura_por_email(destinatario: str, pdf_path: str, numero_factura: str) -> bool:
    if MODO_SIMULADO:
        print(f"[SIMULADO] Enviando factura {numero_factura} a {destinatario} (PDF: {pdf_path})")
        return True

    # Aquí pondrías la integración real con SendGrid/Resend
    # Ejemplo con Resend:
    # import resend
    # resend.api_key = os.getenv("RESEND_API_KEY")
    # with open(pdf_path, "rb") as f:
    #     resend.Emails.send({
    #         "from": "facturas@vibrapay.com",
    #         "to": destinatario,
    #         "subject": f"Factura {numero_factura}",
    #         "text": "Adjuntamos tu factura.",
    #         "attachments": [{"filename": os.path.basename(pdf_path), "content": f.read()}],
    #     })
    # return True

    return False  # Si no está configurado