from enum import StrEnum

class RoleUtilisateur(StrEnum):
    PATIENT = "patient"
    MEDECIN = "medecin"
    ADMIN = "admin"
    SECRETAIRE = "secretaire"
    SUPER_ADMIN = "super_admin"
