## Scénario de test complet — BP Monitor Mobile

---

## 🔧 Préparation

```bash
# Démarrer le backend
docker-compose up -d

# Vérifier
curl http://localhost:8000/health

# Lancer Flutter
cd mobile
flutter run
```

---

## 📋 Données de test disponibles

```
Super Admin :
  email    : admin@bpmonitor.com
  password : secret

Médecin :
  email    : kofi.mensah@bpmonitor.com
  password : secret

Patient :
  email    : ama.koffi@bpmonitor.com
  password : secret

Organisations :
  code : HOPITAL_LOME
  code : CLINIQUE_BIASA
```

---

## 🎬 ACTE 1 — Découverte (Onboarding)

```
Contexte : Premier lancement de l'application

ÉTAPE 1.1 — Lancer l'application
  → L'écran onboarding s'affiche automatiquement
  → Page 1 : "Bienvenue sur BP Monitor" ✅

ÉTAPE 1.2 — Parcourir les 6 pages
  → Page 2 : "Préparez-vous" — position correcte ✅
  → Page 3 : "Placez le brassard" ✅
  → Page 4 : "Lisez les chiffres" — exemple 120/80 visible ✅
  → Page 5 : "Règle 3-3-3" — 3 cartes visibles ✅
  → Page 6 : "Comprenez vos résultats" — 4 catégories colorées ✅

ÉTAPE 1.3 — Passer l'onboarding
  → Cliquer "Passer" sur la page 2
  → Redirection vers /login ✅
```

---

## 🎬 ACTE 2 — Inscription d'un nouveau patient

```
Contexte : Un nouveau patient s'inscrit depuis sa clinique

ÉTAPE 2.1 — Aller sur l'écran Register
  → Cliquer "S'inscrire" sur le login ✅

ÉTAPE 2.2 — Remplir le formulaire
  username  : yao.nouvel
  email     : yao.nouvel@email.com
  password  : secret123
  prénom    : Yao
  nom       : Nouvel
  téléphone : +22890000099
  code org  : HOPITAL_LOME
 
ÉTAPE 2.3 — Valider
  → Compte créé ✅
  → Redirigé vers /home ✅
  → Message de bienvenue "Bonjour, Yao" ✅

ÉTAPE 2.4 — Vérifier l'accueil
  → Carte "Aucune mesure encore" visible ✅
  → Progression 0/6 ✅
  → Règle 3-3-3 visible ✅
```

---

## 🎬 ACTE 3 — Patient choisit son médecin

```
Contexte : Yao veut se rattacher au Dr Kofi

ÉTAPE 3.1 — Aller sur le profil
  → Cliquer icône profil en haut à droite ✅
  → Profil de Yao affiché ✅
  → Section "Médecin référent" → "Aucun médecin assigné" ✅

ÉTAPE 3.2 — Choisir un médecin
  → Cliquer "Choisir mon médecin" ✅
  → Bottom sheet s'ouvre ✅
  → Tab "Liste des médecins" → Dr Kofi Mensah visible ✅

ÉTAPE 3.3 — Sélectionner Dr Kofi
  → Cliquer sur Dr Kofi → surlignage vert ✅
  → Cliquer "Confirmer le choix" ✅
  → Message "Médecin assigné avec succès !" ✅
  → Profil mis à jour → Dr Kofi affiché ✅
```

---

## 🎬 ACTE 4 — Première session de mesures (Jour 1 — Matin)

```
Contexte : Yao prend ses 3 mesures du matin — Jour 1

ÉTAPE 4.1 — Mesure 1/3 — Normale
  → Cliquer "Nouvelle mesure" ✅
  → Sélectionner Jour 1 / Matin ✅
  → Systolique  : 118
  → Diastolique : 76
  → Pouls       : 72
  → Analyse temps réel → carte verte "Tension normale ✅"
  → Cliquer "Enregistrer" ✅
  → Snackbar "✅ Mesure enregistrée !" ✅
  → Retour accueil → Progression 1/6 ✅

ÉTAPE 4.2 — Mesure 2/3 — Normale
  → Nouvelle mesure → Jour 1 / Matin / Mesure 2
  → Systolique  : 122
  → Diastolique : 78
  → Pouls       : 74
  → Enregistrer ✅
  → Progression 2/6 ✅

ÉTAPE 4.3 — Mesure 3/3 — Élevée
  → Nouvelle mesure → Jour 1 / Matin / Mesure 3
  → Systolique  : 135
  → Diastolique : 87
  → Pouls       : 80
  → Analyse → carte orange "Tension élevée 🟡"
  → Enregistrer ✅
  → Progression 3/6 ✅
  → Dernière mesure → badge "Élevée" ✅
```

---

## 🎬 ACTE 5 — Mesures du soir (Jour 1 — Soir)

```
Contexte : Yao prend ses 3 mesures du soir — Jour 1

ÉTAPE 5.1 — Mesure 1/3 soir — Normale
  → Nouvelle mesure → Jour 1 / Soir / Mesure 1
  → Systolique  : 120
  → Diastolique : 80
  → Pouls       : 70
  → Enregistrer ✅

ÉTAPE 5.2 — Mesure 2/3 soir — Normale
  → Nouvelle mesure → Jour 1 / Soir / Mesure 2
  → Systolique  : 125
  → Diastolique : 82
  → Enregistrer ✅

ÉTAPE 5.3 — Mesure CRITIQUE 🚨
  → Nouvelle mesure → Jour 1 / Soir / Mesure 3
  → Systolique  : 185
  → Diastolique : 115
  → Pouls       : 95
  → Analyse → carte rouge "Tension CRITIQUE 🚨"
  → Enregistrer ✅

  → Vérifier SMS reçu sur téléphone patient ✅
  → Vérifier SMS reçu sur téléphone médecin ✅
  → Alerte créée en base ✅
```

---

## 🎬 ACTE 6 — Consulter l'historique

```
Contexte : Yao consulte son historique après le Jour 1

ÉTAPE 6.1 — Ouvrir l'historique
  → Cliquer "Historique" dans la bottom nav ✅
  → Stats affichées (6 mesures) ✅
  → Moyenne systolique calculée ✅

ÉTAPE 6.2 — Vérifier le graphique
  → Courbe rouge (systolique) visible ✅
  → Courbe verte pointillée (diastolique) ✅
  → Points sur les 6 mesures ✅

ÉTAPE 6.3 — Sessions récentes
  → Session "Aujourd'hui" visible ✅
  → Nombre de mesures : 6 ✅
  → Badge catégorie cohérent ✅
  → Moyennes correctes ✅
```

---

## 🎬 ACTE 7 — Consulter les alertes patient

```
Contexte : Yao vérifie ses alertes

ÉTAPE 7.1 — Ouvrir les alertes
  → Cliquer "Alertes" dans la bottom nav ✅
  → Badge rouge avec "1" visible dans l'appbar ✅

ÉTAPE 7.2 — Vérifier l'alerte critique
  → Alerte "Critique 🚨" visible en premier ✅
  → Systolique 185 / Diastolique 115 affichés ✅
  → Message d'alerte visible ✅
  → Statut "EN_ATTENTE" ✅
```

---

## 🎬 ACTE 8 — Connexion médecin

```
Contexte : Dr Kofi se connecte pour traiter les alertes

ÉTAPE 8.1 — Déconnexion patient
  → Profil → "Se déconnecter" ✅
  → Dialogue confirmation → Confirmer ✅
  → Retour vers /login ✅

ÉTAPE 8.2 — Connexion médecin
  → identifiant : kofi.mensah@bpmonitor.com
  → password    : secret
  → Connexion ✅
  → Redirigé vers /medecin/dashboard ✅

ÉTAPE 8.3 — Vérifier le dashboard
  → "Dr. Kofi Mensah" affiché ✅
  → Stats : Alertes critiques = 1 ✅
  → Carte patient critique visible ✅
  → Systolique 185 / Diastolique 115 ✅
```

---

## 🎬 ACTE 9 — Médecin traite l'alerte

```
Contexte : Dr Kofi acquitte l'alerte de Yao

ÉTAPE 9.1 — Acquitter l'alerte
  → Cliquer "Acquitter" sur la carte ✅
  → Dialogue "Confirmez-vous avoir pris en charge ?" ✅
  → Cliquer "Confirmer" ✅
  → Snackbar "✅ Alerte acquittée" ✅
  → Alerte disparaît du dashboard ✅
  → Stats : Alertes critiques = 0 ✅

ÉTAPE 9.2 — Inviter un patient
  → Cliquer "Inviter un patient" ✅
  → Code généré (ex: ABC12345) ✅
  → Noter le code ✅
```

---

## 🎬 ACTE 10 — Connexion Admin

```
Contexte : L'admin gère la plateforme

ÉTAPE 10.1 — Connexion admin
  → Déconnecter le médecin ✅
  → identifiant : admin@bpmonitor.com
  → password    : secret ✅
  → Redirigé vers /medecin/dashboard ✅
  → Section "Administration" visible ✅

ÉTAPE 10.2 — Gérer les organisations
  → Cliquer "Gérer les organisations" ✅
  → Liste : HOPITAL_LOME + CLINIQUE_BIASA ✅
  → Bouton "+" → créer nouvelle organisation ✅
  → nom  : Centre Médical Bè
  → code : CENTRE_BE ✅
  → Organisation créée et listée ✅

ÉTAPE 10.3 — Gérer les utilisateurs
  → Retour dashboard → "Gérer les utilisateurs" ✅
  → Liste de tous les utilisateurs ✅
  → Filtrer par "Médecins" → seuls les médecins ✅
  → Filtrer par "Patients" → seuls les patients ✅
  → Créer un nouveau médecin :
      username  : dr.nouvelle
      email     : dr.nouvelle@email.com
      password  : secret123
      role      : medecin ✅
  → Médecin créé et visible dans la liste ✅

ÉTAPE 10.4 — Voir les rôles
  → Retour dashboard → "Gérer les rôles" ✅
  → 4 rôles listés ✅
  → Cliquer "Super Admin" → permissions expand ✅
  → Cliquer "Patient" → 4 permissions ✅
```

---

## 🎬 ACTE 11 — Patient utilise le code invitation

```
Contexte : Yao utilise le code d'invitation du Dr Kofi

ÉTAPE 11.1 — Reconnecter Yao
  → Déconnecter admin ✅
  → identifiant : yao.nouvel@email.com
  → password    : secret123 ✅

ÉTAPE 11.2 — Utiliser le code
  → Profil → "Choisir mon médecin" ✅
  → Tab "Code invitation" ✅
  → Entrer le code : ABC12345 ✅
  → Cliquer "Valider le code" ✅
  → "Invitation acceptée !" ✅
  → Médecin mis à jour sur le profil ✅
```

---

## ✅ Checklist finale

```
Onboarding       ✅ 6 pages complètes
Register         ✅ avec code organisation
Login            ✅ email + username + téléphone
Accueil          ✅ dernière mesure + progression
Saisie           ✅ analyse temps réel + enregistrement
Alerte critique  ✅ SMS patient + médecin
Historique       ✅ graphique + sessions
Alertes patient  ✅ liste + statut
Dashboard médecin ✅ alertes + acquittement
Admin orgs       ✅ créer organisation
Admin users      ✅ créer utilisateur + filtres
Admin rôles      ✅ permissions expandables
Invitation       ✅ générer + accepter code
Déconnexion      ✅ token supprimé
```

---

## Commandes de vérification en base

```bash
# Vérifier les mesures créées
docker-compose exec db psql -U bp_user -d bp_monitor \
  -c "SELECT id, patient_id, systolique, diastolique, categorie FROM mesures ORDER BY id DESC;"

# Vérifier les alertes
docker-compose exec db psql -U bp_user -d bp_monitor \
  -c "SELECT id, patient_id, niveau, statut, acquittee_par FROM alertes;"

# Vérifier les invitations
docker-compose exec db psql -U bp_user -d bp_monitor \
  -c "SELECT id, code, medecin_id, patient_id, est_utilise FROM invitations;"

# Vérifier les patients et médecins liés
docker-compose exec db psql -U bp_user -d bp_monitor \
  -c "SELECT p.id, u.email, p.medecin_id, p.organisation_id FROM patients p JOIN users u ON p.user_id = u.id;"
```

---

Suivez les actes dans l'ordre et dites-moi ce que vous voyez à chaque étape. 🚀