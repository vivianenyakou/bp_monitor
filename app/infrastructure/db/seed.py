import asyncio
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.permission import PermissionModel
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.domain.enums.blood_group import BloodGroup
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.auth.password_service import PasswordService

# ── Permissions ───────────────────────────────────────────────────
PERMISSIONS = [
    # Mesures
    {"name": "creer_mesure",            "description": "Créer une mesure de tension"},
    {"name": "voir_ses_mesures",         "description": "Voir ses propres mesures"},
    {"name": "voir_mesures_patients",    "description": "Voir les mesures des patients"},
    {"name": "supprimer_mesure",         "description": "Supprimer une mesure"},
    # Alertes
    {"name": "recevoir_alertes",         "description": "Recevoir les alertes"},
    {"name": "acquitter_alerte",         "description": "Acquitter une alerte"},
    {"name": "configurer_alertes",       "description": "Configurer les seuils d'alerte"},
    # Profil
    {"name": "voir_son_profil",          "description": "Voir son propre profil"},
    {"name": "modifier_son_profil",      "description": "Modifier son propre profil"},
    {"name": "voir_profil_patient",      "description": "Voir le profil d'un patient"},
    {"name": "lister_patients",          "description": "Lister les patients"},
    # Administration
    {"name": "gerer_utilisateurs",       "description": "Gérer les utilisateurs"},
    {"name": "gerer_roles",              "description": "Gérer les rôles"},
    {"name": "configurer_systeme",       "description": "Configurer le système"},
    {"name": "voir_tableau_bord_admin",  "description": "Voir le tableau de bord admin"},
]


# ── Rôles et leurs permissions ────────────────────────────────────
ROLES = [
    {
        "name": "patient",
        "description": "Patient — saisit ses mesures et consulte son historique",
        "permissions": [
            "creer_mesure",
            "voir_ses_mesures",
            "voir_son_profil",
            "modifier_son_profil",
        ],
    },
    {
        "name": "medecin",
        "description": "Médecin — consulte les patients et reçoit les alertes",
        "permissions": [
            "creer_mesure",
            "voir_ses_mesures",
            "voir_mesures_patients",
            "recevoir_alertes",
            "acquitter_alerte",
            "configurer_alertes",
            "voir_son_profil",
            "modifier_son_profil",
            "voir_profil_patient",
            "lister_patients",
        ],
    },
    {
        "name": "admin",
        "description": "Administrateur — accès complet au système",
        "permissions": [p["name"] for p in PERMISSIONS],  # toutes les permissions
    },
    {
        "name": "super_admin",
        "description": "Super Administrateur — accès complet au système",
        "permissions": [p["name"] for p in PERMISSIONS],  # toutes les permissions
    },
]


# ── Utilisateurs de test ──────────────────────────────────────────

ORGANISATIONS = [
    {
        "nom": "Hôpital de Lomé",
        "code": "HOPITAL_LOME",
        "adresse": "Boulevard du 13 Janvier, Lomé",
        "telephone": "+22893330326",
        "email": "contact@hopital-lome.tg",
    },
    # {
    #     "nom": "Clinique Biasa",
    #     "code": "CLINIQUE_BIASA",
    #     "adresse": "Lomé, Togo",
    #     "telephone": "+22898295689",
    #     "email": "contact@biasa.tg",
    # },
    # {
    #     "nom": "Centre de Santé de Kara",
    #     "code": "CENTRE_KARA",
    #     "adresse": "Kara, Togo",
    #     "telephone": "+22893330326",
    #     "email": "contact@kara.tg",
    # },
    # {
    #     "nom": "Hôpital de Sokodé",
    #     "code": "HOPITAL_SOKODE",
    #     "adresse": "Sokodé, Togo",
    #     "telephone": "+22893330326",
    #     "email": "contact@sokode.tg",
    # },
]

USERS = [
    {
        "username": "admin",
        "first_name": "Super",
        "last_name": "Admin",
        "email": "admin@bpmonitor.com",
        "password_hash": PasswordService.hasher("secret"),  # secret
        "phone_number": "+22898295689",
        "is_active": True,
        "email_confirmed": True,
        "role": RoleUtilisateur.SUPER_ADMIN,
    },
    # {
    #     "username": "dr.kofi",
    #     "first_name": "Kofi",
    #     "last_name": "Mensah",
    #     "email": "kofi.mensah@bpmonitor.com",
    #     "password_hash": PasswordService.hasher("secret"),  # secret
    #     "phone_number": "+22898295689",
    #     "is_active": True,
    #     "email_confirmed": True,
    #     "role": RoleUtilisateur.MEDECIN,
    # },
    # {
    #     "username": "ama.patient",
    #     "first_name": "Ama",
    #     "last_name": "Koffi",
    #     "email": "ama.koffi@bpmonitor.com",
    #     "password_hash": PasswordService.hasher("secret"),  # secret
    #     "phone_number": "+22898295689",
    #     "is_active": True,
    #     "email_confirmed": True,
    #     "role": RoleUtilisateur.PATIENT,
    # },
]


# ── Profils patients ──────────────────────────────────────────────
# PATIENTS = [
#     {
#         "email": "ama.koffi@bpmonitor.com",
#         "gender": "F",
#         "birth_date": date(1990, 5, 15),
#         "address": "Lomé, Togo",
#         "emergency_contact": "+22898295689",
#         "blood_group": BloodGroup.A_PLUS,
#     },
# ]

# Valeurs par défaut pour chaque organisation
# Valeurs par défaut pour chaque organisation
CONFIGS_DEFAUT = {
    # Créneaux horaires
    "creneau_matin_debut":    {"valeur": "0",    "description": "Début créneau matin (heure UTC)"},
    "creneau_matin_fin":      {"valeur": "9",    "description": "Fin créneau matin (heure UTC)"},
    "creneau_soir_debut":     {"valeur": "18",   "description": "Début créneau soir (heure UTC)"},
    "creneau_soir_fin":       {"valeur": "22",   "description": "Fin créneau soir (heure UTC)"},

    # Test / Debug
    "debug_heure_simulee":    {"valeur": "",     "description": "Heure simulée pour tests (vide = heure réelle)"},
    "app_env":                {"valeur": "prod", "description": "Environnement (prod / test)"},

    # Seuils BP
    "seuil_sys_eleve":        {"valeur": "130",  "description": "Seuil systolique élevé (mmHg)"},
    "seuil_dia_eleve":        {"valeur": "85",   "description": "Seuil diastolique élevé (mmHg)"},
    "seuil_sys_hypertension": {"valeur": "140",  "description": "Seuil systolique hypertension (mmHg)"},
    "seuil_dia_hypertension": {"valeur": "90",   "description": "Seuil diastolique hypertension (mmHg)"},
    "seuil_sys_critique":     {"valeur": "180",  "description": "Seuil systolique critique (mmHg)"},
    "seuil_dia_critique":     {"valeur": "110",  "description": "Seuil diastolique critique (mmHg)"},

    # QR Code
    "qrcode_expiration_jours": {"valeur": "30",  "description": "Durée d'expiration des QR codes (jours)"},
}

# ── Fonctions ─────────────────────────────────────────────────────
async def seed_tenants(session: AsyncSession) -> dict[str, OrganisationModel]:
    print("⏳ Création des organisations...")
    tenants_map = {}

    for data in ORGANISATIONS:
        result = await session.execute(
            select(OrganisationModel).where(OrganisationModel.code == data["code"])
        )
        tenant = result.scalar_one_or_none()

        if not tenant:
            tenant = OrganisationModel(**data)
            session.add(tenant)
            await session.flush()
            print(f"   ✅ Organisation créée : {data['nom']}")
        else:
            print(f"   ⏭️  Organisation existante : {data['nom']}")

        tenants_map[data["code"]] = tenant

    return tenants_map

async def seed_permissions(session: AsyncSession) -> dict[str, PermissionModel]:
    """Crée les permissions si elles n'existent pas."""
    print("⏳ Création des permissions...")
    permissions_map = {}

    for data in PERMISSIONS:
        result = await session.execute(
            select(PermissionModel).where(PermissionModel.name == data["name"])
        )
        permission = result.scalar_one_or_none()

        if not permission:
            permission = PermissionModel(
                name=data["name"],
                description=data["description"],
            )
            session.add(permission)
            await session.flush()
            print(f"   ✅ Permission créée : {data['name']}")
        else:
            print(f"   ⏭️  Permission existante : {data['name']}")

        permissions_map[data["name"]] = permission

    return permissions_map

async def seed_roles(
    session: AsyncSession,
    permissions_map: dict[str, PermissionModel],
) -> dict[str, RoleModel]:
    """Crée les rôles et leur assigne les permissions."""
    print("\n⏳ Création des rôles...")
    roles_map = {}

    for data in ROLES:
        result = await session.execute(
            select(RoleModel).where(RoleModel.name == data["name"])
        )
        role = result.scalar_one_or_none()

        if not role:
            role = RoleModel(
                name=data["name"],
                description=data["description"],
            )
            role.permissions = [
                permissions_map[p]
                for p in data["permissions"]
                if p in permissions_map
            ]
            session.add(role)
            await session.flush()
            print(f"   ✅ Rôle créé : {data['name']} ({len(data['permissions'])} permissions)")
        else:
            print(f"   ⏭️  Rôle existant : {data['name']}")

        roles_map[data["name"]] = role

    return roles_map

async def seed_users(
    session: AsyncSession,
    roles_map: dict[str, RoleModel],
) -> dict[str, UserModel]:
    """Crée les utilisateurs de test."""
    print("\n⏳ Création des utilisateurs...")
    users_map = {}

    for data in USERS:
        result = await session.execute(
            select(UserModel).where(UserModel.email == data["email"])
        )
        user = result.scalar_one_or_none()

        if not user:
            role_name = data.pop("role")
            user = UserModel(**data)
            user.roles = [roles_map[role_name]]
            session.add(user)
            await session.flush()
            print(f"   ✅ Utilisateur créé : {data['email']} [{role_name}]")
        else:
            print(f"   ⏭️  Utilisateur existant : {data['email']}")

        users_map[data["email"]] = user

    return users_map


async def seed_patients(
    session: AsyncSession,
    users_map: dict[str, UserModel],
) -> None:
    """Crée les profils patients."""
    print("\n⏳ Création des profils patients...")

    for data in PATIENTS:
        email = data.pop("email")
        user = users_map.get(email)

        if not user:
            print(f"   ⚠️  Utilisateur introuvable : {email}")
            continue

        result = await session.execute(
            select(PatientModel).where(PatientModel.user_id == user.id)
        )
        patient = result.scalar_one_or_none()

        if not patient:
            patient = PatientModel(user_id=user.id, **data)
            session.add(patient)
            print(f"   ✅ Profil patient créé pour : {email}")
        else:
            print(f"   ⏭️  Profil patient existant pour : {email}")


async def run_seed() -> None:
    """Point d'entrée principal du seed."""
    print("\n🌱 Démarrage du seed BP Monitor...\n")

    async with AsyncSessionFactory() as session:
        try:
            permissions_map = await seed_permissions(session)
            roles_map = await seed_roles(session, permissions_map)
            users_map = await seed_users(session, roles_map)
            await seed_tenants(session)
            # await seed_patients(session, users_map)

            await session.commit()
            print("\n✅ Seed terminé avec succès !\n")

        except Exception as e:
            await session.rollback()
            print(f"\n❌ Erreur pendant le seed : {e}")
            raise


if __name__ == "__main__":
    asyncio.run(run_seed())