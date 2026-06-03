from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.auth.user import UserModel


class ListerPatientsUseCase:
    """
    Liste tous les patients avec leurs informations complètes.
    Filtre par organisation si fourni.
    """

    async def executer(
        self,
        organisation_id: int | None = None,
    ) -> list[dict]:
        async with AsyncSessionFactory() as session:

            query = (
                select(PatientModel)
                .options(selectinload(PatientModel.user))
                .order_by(PatientModel.id.desc())
            )

            if organisation_id:
                query = query.where(
                    PatientModel.organisation_id == organisation_id
                )

            result   = await session.execute(query)
            patients = result.scalars().all()

            return [self._to_dict(p) for p in patients]

    def _to_dict(self, patient: PatientModel) -> dict:
        user = patient.user
        return {
            "id":                patient.id,
            "user_id":           patient.user_id,
            "nom_complet":       f"{user.first_name or ''} {user.last_name or ''}".strip()
                                 or user.username
                                 or user.phone_number
                                 or "Utilisateur",
            "username":          user.username,
            "email":             user.email,
            "telephone":         user.phone_number,
            "gender":            patient.gender,
            "birth_date":        str(patient.birth_date) if patient.birth_date else None,
            "blood_group":       patient.blood_group,
            "address":           patient.address,
            "emergency_contact": patient.emergency_contact,
            "medecin_id":        patient.medecin_id,
            "organisation_id":   patient.organisation_id,
            "is_active":         user.is_active,
            "created_on":        str(patient.created_on) if patient.created_on else None,
            # Seuils personnalisés
            "seuils": {
                "systolique_eleve":            patient.seuil_systolique_eleve,
                "diastolique_eleve":           patient.seuil_diastolique_eleve,
                "systolique_hypertension":     patient.seuil_systolique_hypertension,
                "diastolique_hypertension":    patient.seuil_diastolique_hypertension,
                "systolique_critique":         patient.seuil_systolique_critique,
                "diastolique_critique":        patient.seuil_diastolique_critique,
            },
        }
