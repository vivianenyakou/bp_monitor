from enum import StrEnum

class RoleUtilisateur(StrEnum):
    PATIENT = "patient"
    MEDECIN = "medecin"
    ADMIN = "admin"
    SuperAdmin = "superadmin"