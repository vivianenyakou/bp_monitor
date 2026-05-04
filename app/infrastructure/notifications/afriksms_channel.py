import httpx

from app.core.config import get_settings
from app.core.exceptions import NotificationDeliveryError

settings = get_settings()

BASE_URL = "https://api.afriksms.com/api/web/web_v1/outbounds/send"


class AfrikSmsChannel:
    """
    Adaptateur AfrikSMS — envoie des SMS via l'API AfrikSMS.
    Utilisé pour les alertes critiques de tension artérielle.
    """

    async def envoyer(self, telephone: str, message: str) -> bool:
        """Envoie un SMS au numéro donné."""

        if not all([
            settings.afriksms_client_id,
            settings.afriksms_api_key,
            settings.afriksms_sender_id,
        ]):
            raise NotificationDeliveryError(
                "Configuration AfrikSMS manquante "
                "(AFRIKSMS_CLIENT_ID, AFRIKSMS_API_KEY, AFRIKSMS_SENDER_ID)."
            )

        payload = {
            "ClientId": settings.afriksms_client_id,
            "ApiKey": settings.afriksms_api_key,
            "SenderId": settings.afriksms_sender_id,
            "Message": message,
            "MobileNumbers": self._formater_telephone(telephone),
        }

        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(BASE_URL, params=payload)

            if not response.is_success:
                raise NotificationDeliveryError(
                    f"AfrikSMS — erreur HTTP {response.status_code}"
                )

            # AfrikSMS peut répondre en JSON ou en texte selon la config
            try:
                data = response.json()
                if not data.get("success", True):
                    raise NotificationDeliveryError(
                        f"AfrikSMS — {data.get('message', 'Erreur inconnue')}"
                    )
            except ValueError:
                # Réponse non JSON → OK si HTTP 200
                pass

            return True

        except httpx.TimeoutException:
            raise NotificationDeliveryError("AfrikSMS — timeout dépassé.")
        except httpx.RequestError as e:
            raise NotificationDeliveryError(f"AfrikSMS — erreur réseau : {e}")

    @staticmethod
    def _formater_telephone(telephone: str) -> str:
        """
        Formate le numéro pour AfrikSMS.
        Ex: +228 90 00 00 00 → 22890000000
        """
        telephone = telephone.replace("+", "").replace(" ", "").replace("-", "")

        # Supprimer le 0 initial si présent
        if telephone.startswith("0"):
            telephone = telephone[1:]

        # Ajouter l'indicatif Togo si numéro local (8 chiffres)
        if len(telephone) == 8:
            telephone = "228" + telephone

        return telephone