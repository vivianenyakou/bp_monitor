from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import RegisterDTO, TokenDTO
from app.application.services.phone_number_formatter import normaliser_telephone_togo
from app.core.exceptions import ConflictError, NotFoundError
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.token import TokenModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
import re
import unicodedata
import re
import unicodedata
from datetime import datetime


# ── Fonctions utilitaires ─────────────────────────────────────────
def _normaliser_telephone(telephone: str) -> str:
    tel = telephone.strip().replace(" ", "").replace("-", "").replace("(", "").replace(")", "")

    if tel.startswith("+"):
        return tel

    if tel.startswith("00228"):
        return "+" + tel[2:]
    if tel.startswith("228"):
        return "+" + tel

    if len(tel) == 8:
        return "+228" + tel

    return "+228" + tel

def _normaliser_texte(texte: str) -> str:
    """Supprime les accents et caractères spéciaux."""
    texte = unicodedata.normalize('NFD', texte)
    texte = ''.join(c for c in texte if unicodedata.category(c) != 'Mn')
    texte = re.sub(r'[^a-zA-Z0-9.]', '', texte)
    return texte.lower()


async def _generer_username(
    session, first_name: str | None, last_name: str | None
) -> str:
    """Génère un username unique depuis prénom + nom."""
    base = "utilisateur"
    if first_name and last_name:
        base = f"{_normaliser_texte(first_name)}.{_normaliser_texte(last_name)}"
    elif first_name:
        base = _normaliser_texte(first_name)
    elif last_name:
        base = _normaliser_texte(last_name)

    username  = base
    compteur  = 0
    while True:
        result = await session.execute(
            select(UserModel).where(UserModel.username == username)
        )
        if not result.scalar_one_or_none():
            break
        compteur += 1
        username = f"{base}.{compteur}"

    return username

async def _generer_email(
    session,
    username: str,
    organisation=None,
) -> str:
    """Génère un email unique depuis username + domaine."""
    if organisation and organisation.email:
        domaine = organisation.email.split("@")[-1]
    else:
        domaine = "bpmonitor.com"

    email    = f"{username}@{domaine}"
    compteur = 0
    while True:
        result = await session.execute(
            select(UserModel).where(UserModel.email == email)
        )
        if not result.scalar_one_or_none():
            break
        compteur += 1
        email = f"{username}.{compteur}@{domaine}"

    return email


# ── Use Case ──────────────────────────────────────────────────────
class RegisterUseCase:

    async def executer(self, dto: RegisterDTO) -> TokenDTO:
        async with AsyncSessionFactory() as session:

            # 1. Normaliser le téléphone
         # Après
            phone = None
            if dto.phone_number:
                phone = _normaliser_telephone(dto.phone_number)
            # 2. Trouver l'organisation
            organisation         = None
            medecin_id_depuis_qr = None

            # Option A — via code organisation
            if dto.organisation_code:
                result = await session.execute(
                    select(OrganisationModel)
                    .where(OrganisationModel.code == dto.organisation_code.upper())
                    .where(OrganisationModel.est_actif == True)
                )
                organisation = result.scalar_one_or_none()
                if not organisation:
                    raise NotFoundError(
                        f"Organisation '{dto.organisation_code}' introuvable ou inactive."
                    )

            # Option B — via QR token (prioritaire)
            if dto.qrcode_token:
                qr_result = await session.execute(
                    select(QRCodeModel)
                    .where(QRCodeModel.token == dto.qrcode_token)
                    .where(QRCodeModel.est_actif == True)
                )
                qrcode = qr_result.scalar_one_or_none()

                if qrcode:
                    if not qrcode.expire_le or datetime.utcnow() < qrcode.expire_le:
                        organisation = await session.get(
                            OrganisationModel, qrcode.organisation_id
                        )
                        medecin_id_depuis_qr = qrcode.medecin_id
                        qrcode.nombre_scans += 1
                    else:
                        raise NotFoundError("QR code expiré.")
                else:
                    raise NotFoundError("QR code invalide ou désactivé.")

            # 3. Générer username si non fourni
            username = dto.username
            if not username or username.strip() == "":
                username = await _generer_username(
                    session,
                    dto.first_name,
                    dto.last_name,
                )

            # 4. Générer ou vérifier email
            email = dto.email
            if not email or email.strip() == "":
                # Générer email automatiquement
                email = await _generer_email(session, username, organisation)
            else:
                # Vérifier que l'email fourni n'existe pas déjà
                result = await session.execute(
                    select(UserModel).where(UserModel.email == email)
                )
                if result.scalar_one_or_none():
                    raise ConflictError("Un compte avec cet email existe déjà.")

            # 5. Récupérer le rôle patient par défaut
            result = await session.execute(
                select(RoleModel)
                .where(RoleModel.name == "patient")
                .options(selectinload(RoleModel.permissions))
            )
            role_patient = result.scalar_one_or_none()

            # 6. Créer l'utilisateur
            user = UserModel(
                username=        username,
                email=           email,
                password_hash=   PasswordService.hasher(dto.password),
                first_name=      dto.first_name,
                last_name=       dto.last_name,
                phone_number=    phone,
                is_active=       True,
                organisation_id= organisation.id if organisation else None,
            )
            if role_patient:
                user.roles = [role_patient]

            session.add(user)
            await session.flush()

            # 7. Créer le profil patient
            patient = PatientModel(
                user_id=         user.id,
                organisation_id= organisation.id if organisation else None,
                medecin_id=      medecin_id_depuis_qr,
                birth_date=      dto.birth_date,
            )
            session.add(patient)
            await session.flush()

            # 8. Générer les tokens
            payload       = JWTService.construire_payload(user)
            access_token  = JWTService.creer_access_token(payload)
            refresh_token = JWTService.creer_refresh_token(payload)

            # 9. Sauvegarder le token
            token = TokenModel(
                user_id=       user.id,
                token=         access_token,
                refresh_token= refresh_token,
                expires_at=    datetime.utcnow(),
                revoked=       False,
            )
            session.add(token)
            await session.commit()

            return TokenDTO(
                access_token=  access_token,
                refresh_token= refresh_token,
                username=      username,
                email=         email,
            )