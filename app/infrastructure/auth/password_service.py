import bcrypt

MAX_PASSWORD_LENGTH = 72


class PasswordService:

    @staticmethod
    def hasher(password: str) -> str:
        """Hash un mot de passe en clair."""
        password_bytes = password[:MAX_PASSWORD_LENGTH].encode("utf-8")
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password_bytes, salt).decode("utf-8")

    @staticmethod
    def verifier(password: str, hashed: str) -> bool:
        """Vérifie qu'un mot de passe correspond au hash."""
        password_bytes = password[:MAX_PASSWORD_LENGTH].encode("utf-8")
        hashed_bytes = hashed.encode("utf-8")
        return bcrypt.checkpw(password_bytes, hashed_bytes)