from dataclasses import dataclass
from datetime import datetime


@dataclass
class GenererQRCodeDTO:
    organisation_id: int
    medecin_id:      int | None = None
    description:     str | None = None
    expire_dans_jours: int | None = None  # None = pas d'expiration


@dataclass
class QRCodeDTO:
    id:              int
    token:           str
    organisation_id: int
    organisation_nom: str
    medecin_id:      int | None
    medecin_nom:     str | None
    est_actif:       bool
    expire_le:       datetime | None
    nombre_scans:    int
    description:     str | None
    url:             str   # URL complète du QR code


@dataclass
class ValiderQRCodeDTO:
    token: str


@dataclass
class QRCodeInfoDTO:
    token:            str
    organisation_id:  int
    organisation_nom: str
    organisation_code: str
    medecin_id:       int | None
    medecin_nom:      str | None
    est_valide:       bool
    message:          str | None