from datetime import date, datetime, timezone
from select import select

from app.domain.enums.bp_category import PeriodeMesure
from app.domain.services.creneau_service import CreneauService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.mesure import MesureModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.bp.session import SessionModel


class VerifierCreneauUseCase:
    """Créneau actuel du patient connecté (soir dynamique)."""

    async def executer(self, user_id: int) -> dict:
        async with AsyncSessionFactory() as db:
            res_p = await db.execute(
                select(PatientModel).where(PatientModel.user_id == user_id)
            )
            patient = res_p.scalar_one_or_none()
            org_id = (patient.organisation_id if patient else 1) or 1

            creneau_service = await CreneauService.pour_organisation(org_id)

            premiere_matin = None
            if patient:
                res_s = await db.execute(
                    select(SessionModel)
                    .where(SessionModel.patient_id == patient.id)
                    .where(SessionModel.protocole_termine == False)
                    .order_by(SessionModel.id.desc())
                )
                sess = res_s.scalar_one_or_none()
                if sess:
                    aujourd_hui = date.today()
                    if aujourd_hui == sess.date_jour1: jour = 1
                    elif aujourd_hui == sess.date_jour2: jour = 2
                    elif aujourd_hui == sess.date_jour3: jour = 3
                    else: jour = 1
                    res_m = await db.execute(
                        select(MesureModel)
                        .where(MesureModel.session_id == sess.session_id)
                        .where(MesureModel.periode == PeriodeMesure.MATIN)
                        .where(MesureModel.jour == jour)
                        .where(MesureModel.numero_mesure == 1)
                    )
                    mesure = res_m.scalar_one_or_none()
                    premiere_matin = mesure.prise_le if mesure else None

            creneau_service.definir_ancrage_soir(premiere_matin)
            creneau = creneau_service.creneau_actuel()

            return {
                "creneau":        creneau.value,
                "est_disponible": creneau_service.est_disponible(),
                "heure_utc":      datetime.now(timezone.utc).strftime("%H:%M UTC"),
                "message":        creneau_service.prochain_creneau()
                                  if not creneau_service.est_disponible() else None,
            }