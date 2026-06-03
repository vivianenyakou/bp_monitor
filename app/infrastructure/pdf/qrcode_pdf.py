import io
import qrcode
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

# Couleurs BP Monitor
VERT_PRIMARY  = HexColor('#1B6B3A')
VERT_LIGHT    = HexColor('#E8F5ED')
GRIS_TEXT     = HexColor('#757575')
NOIR_TEXT     = HexColor('#1A1A1A')


def generer_image_qrcode(url: str) -> io.BytesIO: 
    """Génère une image QR code depuis une URL."""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=2,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(
        fill_color="#1B6B3A",
        back_color="white",
    )

    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)
    return buffer


def generer_pdf_qrcode(
    url:              str,
    organisation_nom: str,
    medecin_nom:      str | None,
    description:      str | None,
    expire_le:        str | None,
    nombre_scans:     int,
) -> bytes:
    """
    Génère un PDF professionnel avec le QR code.
    Retourne les bytes du PDF.
    """
    buffer = io.BytesIO()
    c      = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    # ── Fond header ──────────────────────────────────────────────
    c.setFillColor(VERT_PRIMARY)
    c.rect(0, height - 6 * cm, width, 6 * cm, fill=True, stroke=False)

    # ── Logo / Titre header ───────────────────────────────────────
    c.setFillColor(HexColor('#FFFFFF'))
    c.setFont("Helvetica-Bold", 28)
    c.drawCentredString(width / 2, height - 2.5 * cm, "G-AutoBP")

    c.setFont("Helvetica", 14)
    c.drawCentredString(
        width / 2,
        height - 3.5 * cm,
        "Application de suivi de tension artérielle",
    )

    # ── Icône cœur ───────────────────────────────────────────────
    c.setFont("Helvetica", 20)
    c.drawCentredString(width / 2, height - 4.8 * cm, "❤️")

    # ── Carte blanche centrale ────────────────────────────────────
    card_y      = height - 22 * cm
    card_height = 15 * cm
    card_x      = 3 * cm
    card_width  = width - 6 * cm

    c.setFillColor(HexColor('#FFFFFF'))
    c.setStrokeColor(HexColor('#E0E0E0'))
    c.roundRect(
        card_x, card_y,
        card_width, card_height,
        radius=10,
        fill=True, stroke=True,
    )

    # ── Organisation ─────────────────────────────────────────────
    c.setFillColor(VERT_PRIMARY)
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(
        width / 2,
        card_y + card_height - 1.5 * cm,
        organisation_nom,
    )

    # ── Médecin ───────────────────────────────────────────────────
    if medecin_nom:
        c.setFillColor(GRIS_TEXT)
        c.setFont("Helvetica", 13)
        c.drawCentredString(
            width / 2,
            card_y + card_height - 2.5 * cm,
            medecin_nom,
        )

    # ── Description ───────────────────────────────────────────────
    if description:
        c.setFillColor(GRIS_TEXT)
        c.setFont("Helvetica-Oblique", 11)
        c.drawCentredString(
            width / 2,
            card_y + card_height - 3.3 * cm,
            description,
        )

    # ── QR Code ───────────────────────────────────────────────────
    qr_buffer   = generer_image_qrcode(url)
    qr_image    = ImageReader(qr_buffer)
    qr_size     = 7 * cm
    qr_x        = (width - qr_size) / 2
    qr_y        = card_y + (card_height - qr_size) / 2 - 0.5 * cm

    c.drawImage(
        qr_image,
        qr_x, qr_y,
        width=qr_size, height=qr_size,
        preserveAspectRatio=True,
    )

    # ── Texte sous le QR ─────────────────────────────────────────
    c.setFillColor(NOIR_TEXT)
    c.setFont("Helvetica-Bold", 13)
    c.drawCentredString(
        width / 2,
        qr_y - 0.8 * cm,
        "Scannez pour télécharger l'application",
    )

    c.setFillColor(GRIS_TEXT)
    c.setFont("Helvetica", 11)
    c.drawCentredString(
        width / 2,
        qr_y - 1.5 * cm,
        "et créer votre compte automatiquement",
    )

    # ── Badge expiration ──────────────────────────────────────────
    if expire_le:
        badge_x = card_x + card_width - 5.5 * cm
        badge_y = card_y + 0.5 * cm

        c.setFillColor(VERT_LIGHT)
        c.roundRect(
            badge_x, badge_y,
            5 * cm, 0.8 * cm,
            radius=5,
            fill=True, stroke=False,
        )
        c.setFillColor(VERT_PRIMARY)
        c.setFont("Helvetica", 9)
        c.drawCentredString(
            badge_x + 2.5 * cm,
            badge_y + 0.2 * cm,
            f"Valide jusqu'au {expire_le}",
        )

    # ── Scans ─────────────────────────────────────────────────────
    c.setFillColor(GRIS_TEXT)
    c.setFont("Helvetica", 9)
    c.drawString(
        card_x + 0.5 * cm,
        card_y + 0.6 * cm,
        f"{nombre_scans} scan(s)",
    )

    # ── Instructions bas de page ──────────────────────────────────
    instructions_y = card_y - 2 * cm

    c.setFillColor(VERT_PRIMARY)
    c.setFont("Helvetica-Bold", 12)
    c.drawCentredString(
        width / 2,
        instructions_y,
        "Comment ça marche ?",
    )

    etapes = [
        ("1", "Scannez le QR code avec votre téléphone"),
        ("2", "Téléchargez l'application G-AutoBP"),
        ("3", "Créez votre compte en quelques secondes"),
        ("4", "Commencez votre suivi de tension"),
    ]

    for i, (num, texte) in enumerate(etapes):
        y = instructions_y - 1 * cm - (i * 0.7 * cm)

        # Cercle numéroté
        c.setFillColor(VERT_PRIMARY)
        c.circle(card_x + 0.6 * cm, y + 0.15 * cm, 0.25 * cm, fill=True)

        c.setFillColor(HexColor('#FFFFFF'))
        c.setFont("Helvetica-Bold", 9)
        c.drawCentredString(card_x + 0.6 * cm, y + 0.08 * cm, num)

        # Texte
        c.setFillColor(NOIR_TEXT)
        c.setFont("Helvetica", 11)
        c.drawString(card_x + 1.2 * cm, y, texte)

    # ── Footer ────────────────────────────────────────────────────
    c.setFillColor(VERT_PRIMARY)
    c.rect(0, 0, width, 1.2 * cm, fill=True, stroke=False)

    c.setFillColor(HexColor('#FFFFFF'))
    c.setFont("Helvetica", 9)
    c.drawCentredString(
        width / 2,
        0.4 * cm,
        "G-AutoBP — Votre santé, notre priorité | www.g-autobp.tech",
    )

    c.save()
    buffer.seek(0)
    return buffer.getvalue()