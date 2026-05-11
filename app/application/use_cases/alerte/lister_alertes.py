from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.alerte_dto import AlerteDTO
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.alerte import AlerteModel
from app.infrastructure.models.bp.patient import PatientModel


class ListerAlertesUseCase:

    async def executer(
        self,
        patient_id: int | None = None,
        medecin_id: int | None = None,
    ) -> list[AlerteDTO]:
        async with AsyncSessionFactory() as session:

            query = (
                select(AlerteModel)
                .options(
                    selectinload(AlerteModel.patient).selectinload(PatientModel.user)
                )
                .order_by(AlerteModel.declenchee_le.desc())
            )

            if patient_id:
                query = query.where(AlerteModel.patient_id == patient_id)

            if medecin_id:
                query = query.where(AlerteModel.medecin_id == medecin_id)

            result = await session.execute(query)
            alertes = result.scalars().all()

            return [
                AlerteDTO(
                    id=a.id,
                    patient_id=a.patient_id,
                    medecin_id=a.medecin_id,
                    systolique=a.systolique,
                    diastolique=a.diastolique,
                    niveau=a.niveau,
                    statut=a.statut,
                    message=a.message,
                    declenchee_le=a.declenchee_le,
                    acquittee_le=a.acquittee_le,
                    acquittee_par=a.acquittee_par,
                    patient_nom_complet=self._nom_complet(a),
                    patient_telephone=self._telephone(a),
                )
                for a in alertes
            ]

    @staticmethod
    def _nom_complet(a: AlerteModel) -> str | None:
        if not a.patient or not a.patient.user:
            return None
        u = a.patient.user
        return f"{u.first_name or ''} {u.last_name or ''}".strip() or u.username

    @staticmethod
    def _telephone(a: AlerteModel) -> str | None:
        if not a.patient or not a.patient.user:
            return None
        return a.patient.user.phone_number
