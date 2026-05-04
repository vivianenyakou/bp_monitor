from http import HTTPStatus

#toutes les erreurs possibles du système
class BPMonitorException(Exception):
    """Exception de base du microservice."""
    status_code: int = HTTPStatus.INTERNAL_SERVER_ERROR
    message: str = "Une erreur interne est survenue."

    def __init__(self, message: str | None = None) -> None:
        self.message = message or self.__class__.message
        super().__init__(self.message)


# ── Domain ───────────────────────────────────────────────────────
class DomainException(BPMonitorException):
    status_code = HTTPStatus.UNPROCESSABLE_ENTITY
    message = "Règle métier violée."

class InvalidBloodPressureError(DomainException):
    message = "Valeurs de tension artérielle invalides."

class InvalidThresholdError(DomainException):
    message = "Seuils de tension invalides."

class MeasurementSessionIncompleteError(DomainException):
    message = "Session incomplète — 18 mesures requises."


# ── Application ──────────────────────────────────────────────────
class ApplicationException(BPMonitorException):
    status_code = HTTPStatus.BAD_REQUEST
    message = "Erreur applicative."

class NotFoundError(ApplicationException):
    status_code = HTTPStatus.NOT_FOUND
    message = "Ressource introuvable."

class PatientNotFoundError(NotFoundError):
    message = "Patient introuvable."

class MeasurementNotFoundError(NotFoundError):
    message = "Mesure introuvable."

class AlertNotFoundError(NotFoundError):
    message = "Alerte introuvable."

class DoctorNotFoundError(NotFoundError):
    message = "Médecin introuvable."

class ConflictError(ApplicationException):
    status_code = HTTPStatus.CONFLICT
    message = "Conflit — ressource déjà existante."


# ── Auth ─────────────────────────────────────────────────────────
class AuthException(BPMonitorException):
    status_code = HTTPStatus.UNAUTHORIZED
    message = "Authentification requise."

class InvalidTokenError(AuthException):
    message = "Token invalide ou expiré."

class InvalidCredentialsError(AuthException):
    message = "Identifiants incorrects."

class PermissionDeniedError(BPMonitorException):
    status_code = HTTPStatus.FORBIDDEN
    message = "Permission refusée."


# ── Infrastructure ───────────────────────────────────────────────
class InfrastructureException(BPMonitorException):
    status_code = HTTPStatus.SERVICE_UNAVAILABLE
    message = "Service externe indisponible."

class NotificationDeliveryError(InfrastructureException):
    message = "Échec de l'envoi de la notification."

class CacheError(InfrastructureException):
    message = "Erreur du cache Redis."

class DatabaseError(InfrastructureException):
    message = "Erreur base de données."