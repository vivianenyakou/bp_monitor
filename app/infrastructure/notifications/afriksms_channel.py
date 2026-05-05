import httpx

from app.core.config import get_settings
from app.core.exceptions import NotificationDeliveryError

settings = get_settings()

BASE_URL = "https://api.afriksms.com/api/web/web_v1/outbounds/send"


class AfrikSmsChannel:

    async def envoyer(self, telephone: str, message: str) -> bool:

        if not all([
            settings.afriksms_client_id,
            settings.afriksms_api_key,
            settings.afriksms_sender_id,
        ]):
            raise NotificationDeliveryError(
                "Configuration AfrikSMS manquante."
            )

        telephone_formate = self._formater_telephone(telephone)

        payload = {
            "ClientId": settings.afriksms_client_id,
            "ApiKey": settings.afriksms_api_key,
            "SenderId": settings.afriksms_sender_id,
            "Message": message,
            "MobileNumbers": telephone_formate,
        }

        print(f"[AfrikSMS] Téléphone formaté : {telephone_formate}")
        print(f"[AfrikSMS] ClientId : {settings.afriksms_client_id}")
        print(f"[AfrikSMS] SenderId : {settings.afriksms_sender_id}")

        try:
            async with httpx.AsyncClient(timeout=10) as client:

                # Essai 1 — GET avec params dans l'URL
                response = await client.get(BASE_URL, params=payload)
                print(f"[AfrikSMS] GET params → Status : {response.status_code}")
                print(f"[AfrikSMS] Réponse : {response.text}")

                # Si 401 → essayer POST avec form data
                if response.status_code == 401:
                    response = await client.post(BASE_URL, data=payload)
                    print(f"[AfrikSMS] POST data → Status : {response.status_code}")
                    print(f"[AfrikSMS] Réponse : {response.text}")

                # Si encore 401 → essayer POST avec JSON
                if response.status_code == 401:
                    response = await client.post(BASE_URL, json=payload)
                    print(f"[AfrikSMS] POST json → Status : {response.status_code}")
                    print(f"[AfrikSMS] Réponse : {response.text}")

            if not response.is_success:
                raise NotificationDeliveryError(
                    f"AfrikSMS — erreur HTTP {response.status_code} : {response.text}"
                )

            try:
                data = response.json()
                if not data.get("success", True):
                    raise NotificationDeliveryError(
                        f"AfrikSMS — {data.get('message', 'Erreur inconnue')}"
                    )
            except ValueError:
                pass

            return True

        except httpx.TimeoutException:
            raise NotificationDeliveryError("AfrikSMS — timeout dépassé.")
        except httpx.RequestError as e:
            raise NotificationDeliveryError(f"AfrikSMS — erreur réseau : {e}")

    @staticmethod
    def _formater_telephone(telephone: str) -> str:
        telephone = telephone.replace("+", "").replace(" ", "").replace("-", "")
        if telephone.startswith("0"):
            telephone = telephone[1:]
        if len(telephone) == 8:
            telephone = "228" + telephone
        return telephone