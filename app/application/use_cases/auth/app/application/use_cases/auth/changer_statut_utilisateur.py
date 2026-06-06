from app.core.exceptions import NotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.user import UserModel


class ChangerStatutUtilisateurUseCase:
    async def executer(self, user_id: int, is_active: bool) -> dict:
        async with AsyncSessionFactory() as session:
            user = await session.get(UserModel, user_id)
            if not user:
                raise NotFoundError("Utilisateur introuvable.")

            user.is_active = is_active
            await session.commit()
            await session.refresh(user)

            return {
                "id": user.id,
                "is_active": user.is_active,
                "message": "Compte active." if is_active else "Compte desactive.",
            }