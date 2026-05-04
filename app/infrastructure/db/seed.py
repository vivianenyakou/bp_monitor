import asyncio
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.permission import PermissionModel
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.domain.enums.blood_group import BloodGroup


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
]


# ── Utilisateurs de test ──────────────────────────────────────────
USERS = [
    {
        "username": "admin",
        "first_name": "Super",
        "last_name": "Admin",
        "email": "admin@bpmonitor.com",
        "password_hash": "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW",  # secret
        "phone_number": "+228 98 29 56 89",
        "is_active": True,
        "email_confirmed": True,
        "role": "admin",
    },
    {
        "username": "dr.kofi",
        "first_name": "Kofi",
        "last_name": "Mensah",
        "email": "kofi.mensah@bpmonitor.com",
        "password_hash": "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW",  # secret
        "phone_number": "+228 98 29 56 89",
        "is_active": True,
        "email_confirmed": True,
        "role": "medecin",
    },
    {
        "username": "ama.patient",
        "first_name": "Ama",
        "last_name": "Koffi",
        "email": "ama.koffi@bpmonitor.com",
        "password_hash": "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW",  # secret
        "phone_number": "+228 98 29 56 89",
        "is_active": True,
        "email_confirmed": True,
        "role": "patient",
    },
]


# ── Profils patients ──────────────────────────────────────────────
PATIENTS = [
    {
        "email": "ama.koffi@bpmonitor.com",
        "gender": "F",
        "birth_date": date(1990, 5, 15),
        "address": "Lomé, Togo",
        "emergency_contact": "+228 98 29 56 89",
        "blood_group": BloodGroup.A_PLUS,
    },
]


# ── Fonctions ─────────────────────────────────────────────────────
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
            await seed_patients(session, users_map)

            await session.commit()
            print("\n✅ Seed terminé avec succès !\n")
            print("📋 Comptes disponibles :")
            print("   Email                      | Mot de passe | Rôle")
            print("   ---------------------------|--------------|--------")
            print("   admin@bpmonitor.com        | secret       | admin")
            print("   kofi.mensah@bpmonitor.com  | secret       | medecin")
            print("   ama.koffi@bpmonitor.com    | secret       | patient")

        except Exception as e:
            await session.rollback()
            print(f"\n❌ Erreur pendant le seed : {e}")
            raise


if __name__ == "__main__":
    asyncio.run(run_seed())