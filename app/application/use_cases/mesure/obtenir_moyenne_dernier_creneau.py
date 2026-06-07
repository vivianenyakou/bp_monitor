from sqlalchemy import select

from app.core.exceptions import PatientNotFoundError
from app.domain.services.analyseur_ta import AnalyseurTA
from app.domain.value_objects.tension_arterielle import TensionArterielle
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.mesure import MesureModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.services.config_service import ConfigService


class ObtenirMoyenneDernierCreneauUseCase:
    """Moyenne du dernier créneau COMPLET (3 mesures) du patient, catégorisée."""

    async def executer(self, patient_id: int) -> dict | None:
        async with AsyncSessionFactory() as session:
            # 1. Patient (patient_id = user_id)
            lookup = await session.execute(
                select(PatientModel).where(PatientModel.user_id == patient_id)
            )
            patient = lookup.scalar_one_or_none()
            if not patient:
                raise PatientNotFoundError()

            # 2. Seuils selon le profil (comme dans le use case de mesure)
            seuils = await ConfigService.get_seuils(
                patient.organisation_id or 1, patient.est_hypertendu
            )
            analyseur = AnalyseurTA(seuils)

            # 3. Toutes les mesures du patient, les plus récentes d'abord
            result = await session.execute(
                select(MesureModel)
                .where(MesureModel.patient_id == patient.id)
                .order_by(MesureModel.prise_le.desc())
            )
            mesures = result.scalars().all()
            if not mesures:
                return None

            # 4. Trouver le dernier créneau COMPLET (groupe session+jour+période avec 3 mesures)
            #    On parcourt par ordre décroissant ; le 1er groupe de 3 trouvé est le plus récent.
            groupes: dict[tuple, list] = {}
            for m in mesures:
                cle = (m.session_id, m.jour, m.periode)
                groupes.setdefault(cle, []).append(m)

            # garder l'ordre : la mesure la plus récente donne le créneau le plus récent
            creneau_mesures = None
            for m in mesures:
                cle = (m.session_id, m.jour, m.periode)
                if len(groupes[cle]) >= 3:
                    creneau_mesures = groupes[cle][:3]
                    break

            if not creneau_mesures:
                return None  # aucun créneau complet → le front affichera "en cours"

            # 5. Moyenne du créneau
            moy_sys = round(sum(m.systolique for m in creneau_mesures) / 3)
            moy_dia = round(sum(m.diastolique for m in creneau_mesures) / 3)
            pouls = [m.pouls for m in creneau_mesures if m.pouls]
            moy_pouls = round(sum(pouls) / len(pouls)) if pouls else None

            tension = TensionArterielle(
                systolique=moy_sys, diastolique=moy_dia, pouls=moy_pouls
            )
            categorie = analyseur.categoriser(tension)
            ref = creneau_mesures[0]  # la plus récente du créneau

            return {
                "systolique": moy_sys,
                "diastolique": moy_dia,
                "pouls": moy_pouls,
                "categorie": categorie.value,
                "session_id": ref.session_id,
                "periode": ref.periode.value,
                "jour": ref.jour,
                "prise_le": ref.prise_le.isoformat(),
            }