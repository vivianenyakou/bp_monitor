from dataclasses import dataclass
from datetime import date, datetime


@dataclass
class SessionDTO:
    session_id:        str
    patient_id:        int
    date_jour1:        date
    date_jour2:        date
    date_jour3:        date

    # Progression
    mesures_j1_matin:  int
    mesures_j1_soir:   int
    mesures_j2_matin:  int
    mesures_j2_soir:   int
    mesures_j3_matin:  int
    mesures_j3_soir:   int

    # Statuts
    jour1_complete:    bool
    jour2_complete:    bool
    jour3_complete:    bool
    protocole_termine: bool

    # Créneau actuel
    creneau_actuel:    str   # matin / soir / hors_creneau
    message_creneau:   str   # message si hors créneau

    # Jour actuel
    jour_actuel:       int   # 1, 2 ou 3
    mesures_restantes: int   # dans le créneau actuel

    # Médicament
    medicament_pris:   bool | None

    demarre_le:        datetime
    termine_le:        datetime | None


@dataclass
class CreerMesureAvecSessionDTO:
    patient_id:    int
    systolique:    int
    diastolique:   int
    pouls:         int | None = None
    notes:         str | None = None
    medicament_pris: bool | None = None