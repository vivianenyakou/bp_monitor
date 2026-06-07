from sqlalchemy import select

from app.core.exceptions import NotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.session import SessionModel


class EnregistrerMedicamentUseCase:
    """Enregistre la réponse du patient au pop-up médicament."""

    async def executer(self, session_id: str, medicament_pris: bool) -> dict:
        async with AsyncSessionFactory() as db:
            result = await db.execute(
                select(SessionModel).where(SessionModel.session_id == session_id)
            )
            sess = result.scalar_one_or_none()
            if not sess:
                raise NotFoundError("Session introuvable.")

            sess.medicament_pris = medicament_pris
            await db.commit()

            return {
                "session_id": sess.session_id,
                "medicament_pris": sess.medicament_pris,
            }