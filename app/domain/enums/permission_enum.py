from enum import StrEnum


class Permission(StrEnum):
    # ── Mesures ──────────────────────────────────────────
    CREER_MESURE            = "creer_mesure"
    VOIR_SES_MESURES        = "voir_ses_mesures"
    VOIR_MESURES_PATIENTS   = "voir_mesures_patients"
    SUPPRIMER_MESURE        = "supprimer_mesure"

    # ── Alertes ──────────────────────────────────────────
    RECEVOIR_ALERTES        = "recevoir_alertes"
    ACQUITTER_ALERTE        = "acquitter_alerte"
    CONFIGURER_ALERTES      = "configurer_alertes"

    # ── Profil ───────────────────────────────────────────
    VOIR_SON_PROFIL         = "voir_son_profil"
    MODIFIER_SON_PROFIL     = "modifier_son_profil"
    VOIR_PROFIL_PATIENT     = "voir_profil_patient"
    LISTER_PATIENTS         = "lister_patients"

    # ── Administration ───────────────────────────────────
    GERER_UTILISATEURS      = "gerer_utilisateurs"
    GERER_ROLES             = "gerer_roles"
    CONFIGURER_SYSTEME      = "configurer_systeme"
    VOIR_TABLEAU_BORD_ADMIN = "voir_tableau_bord_admin"