from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt

from app.core.config import get_settings
from app.core.exceptions import InvalidTokenError

settings = get_settings()


class JWTService:

    @staticmethod
    def creer_access_token(data: dict) -> str:
        """Crée un access token JWT."""
        payload = data.copy()
        expiration = datetime.now(timezone.utc) + timedelta(
            minutes=settings.jwt_access_token_expire_minutes
        )
        payload.update({"exp": expiration, "type": "access"})
        return jwt.encode(
            payload,
            settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
        )

    @staticmethod
    def creer_refresh_token(data: dict) -> str:
        """Crée un refresh token JWT."""
        payload = data.copy()
        expiration = datetime.now(timezone.utc) + timedelta(
            days=settings.jwt_refresh_token_expire_days
        )
        payload.update({"exp": expiration, "type": "refresh"})
        return jwt.encode(
            payload,
            settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
        )

    @staticmethod
    def decoder_token(token: str) -> dict:
        """Décode et valide un token JWT."""
        try:
            payload = jwt.decode(
                token,
                settings.jwt_secret_key,
                algorithms=[settings.jwt_algorithm],
            )
            return payload
        except JWTError:
            raise InvalidTokenError()

    @staticmethod
    def construire_payload(user) -> dict:
        return {
            "sub": str(user.id),
            "email": user.email,
            "roles": user.role_names,
            "permissions": user.permission_names,
            "organisation_id": user.organisation_id,
        }