from dataclasses import dataclass


@dataclass
class ConfigDTO:
    cle:             str
    valeur:          str
    description:     str
    organisation_id: int


@dataclass
class MettreAJourConfigDTO:
    organisation_id: int
    cle:             str
    valeur:          str