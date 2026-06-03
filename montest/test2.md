Scénario de test complet — BP Monitor
Comptes de test (seed)
Rôle	Email	Mot de passe
Super Admin	admin@bpmonitor.com	secret
Médecin	kofi.mensah@bpmonitor.com	secret
Patient (existant)	ama.koffi@bpmonitor.com	secret
API Swagger : http://192.168.10.105:8000/docs

App mobile : http://192.168.10.105:8000/api/v1 (configuré dans app_constants.dart)

PHASE 1 — Admin : préparer l'organisation et le QR code
Étape 1.1 — Connexion admin (Swagger ou mobile)

POST /api/v1/auth/login
{
  "identifiant": "admin@bpmonitor.com",
  "password": "secret"
}
→ Copier l'access_token
Étape 1.2 — Générer un QR code pour Clinique Biasa

POST /api/v1/qrcodes/generer
Authorization: Bearer <token>
{
  "organisation_id": 2,
  "medecin_id": <id du médecin dr.kofi>,
  "description": "Accueil principal",
  "expire_dans_jours": 30
}
→ Récupérer le champ "token" et "url" dans la réponse
Pour trouver l'id de dr.kofi :


GET /api/v1/auth/utilisateurs   (ou chercher via /patients/medecins/liste)
PHASE 2 — Médecin : connexion
Étape 2.1 — Se connecter sur le mobile avec le compte médecin

Identifiant : kofi.mensah@bpmonitor.com
Mot de passe : secret
→ Le médecin arrive sur son Dashboard avec la liste des patients et alertes.

PHASE 3 — Patient nouveau : inscription via QR code
Étape 3.1 — Scanner le QR code
Sur le mobile, depuis la page login → "Scanner le QR code de ma clinique"
Scanner le QR généré à l'étape 1.2
Résultat attendu : bannière verte "✅ QR code validé !" avec 🏥 Clinique Biasa et 👨‍⚕️ Kofi Mensah
Le dropdown organisation est masqué (car QR gère tout)
Étape 3.2 — Remplir le formulaire d'inscription

Prénom       : Kossi
Nom          : Attivor
Téléphone    : 90 11 22 33  (→ devient +22890112233)
Date naiss.  : 15/03/1985   (→ affiche "40 ans")
Mot de passe : test1234
→ Taper "Créer mon compte"

Vérifier en BDD ou Swagger :

user.organisation_id = id de Clinique Biasa
patient.medecin_id = id de dr.kofi
patient.birth_date = 1985-03-15
Étape 3.3 — Setup profil (s'affiche une seule fois)

Avez-vous de l'hypertension ? → OUI
Médecin référent              → Dr Kofi Mensah (déjà assigné, sélectionner quand même)
→ "Continuer"
→ Arrivée sur /home

→ Se déconnecter puis reconnecter : setup-profil ne doit plus apparaître

PHASE 4 — Patient : saisir les mesures (Protocole 3 jours)
Créneaux horaires (heure de Lomé = UTC)
Créneau	Plage
🌅 Matin	00h00 – 09h00
🌙 Soir	18h00 – 22h00
⏰ Hors créneau	09h01 – 17h59 et 22h01 – 23h59
JOUR 1 — Créneau Matin (dans la plage 00h–09h)
Aller sur "Saisie mesure" — vérifier que la carte session affiche : 🌅 Matin · Jour 1/3 · Mesure 1/3

Mesure 1 — Tension normale


Systolique  : 122   Diastolique : 79   Pouls : 68
→ Analyse temps réel : ✅ Tension normale
→ "Enregistrer" → Snackbar "2 restante(s) ce créneau"
Mesure 2 — Tension élevée


Systolique  : 133   Diastolique : 87   Pouls : 72
→ Analyse temps réel : 🟡 Tension élevée
→ "Enregistrer" → Snackbar "1 restante(s) ce créneau"
Mesure 3 — Tension normale (3ème = calcul de la moyenne)


Systolique  : 125   Diastolique : 82   Pouls : 70
→ "Enregistrer"
→ Moyenne matin ≈ 127/83 → "élevée" → niveau AVERTISSEMENT
→ Dialog "Médicaments" → répondre "Oui"
→ La carte passe à "Créneau du matin terminé — Revenez ce soir"
JOUR 1 — Créneau Soir (dans la plage 18h–22h)
Mesure 4


Systolique  : 155   Diastolique : 98   Pouls : 80
→ 🔴 Hypertension
Mesure 5


Systolique  : 162   Diastolique : 102  Pouls : 82
Mesure 6 — CRITIQUE (déclenche alerte médecin)


Systolique  : 185   Diastolique : 112  Pouls : 88
→ 🚨 Tension CRITIQUE
→ "Enregistrer"
→ Moyenne soir ≈ 167/104 → AVERTISSEMENT → dialog médicaments
→ SMS envoyé à dr.kofi (si AfrikSMS configuré)
→ Jour 1 : ✅ complet
JOURS 2 et 3 — Répéter la même séquence
Jour 2 Matin — 3 mesures normales (120-128 / 78-83)

Jour 2 Soir — 3 mesures élevées (132-138 / 86-90)

Jour 3 Matin — 3 mesures normales

Jour 3 Soir — 3ème mesure → Dialog 🎉 Félicitations ! Protocole terminé !

Tester "hors créneau"
Entre 09h01 et 17h59 — aller sur Saisie mesure :

Carte orange "Hors créneau de mesure" avec le message backend doit s'afficher, formulaire absent.

PHASE 5 — Médecin : vérifier les alertes
Se connecter avec kofi.mensah@bpmonitor.com sur le mobile :

Dashboard : badge d'alerte visible
Alertes : voir les alertes générées par Kossi (critique soir Jour 1)
Patients : Kossi Attivor doit apparaître dans la liste avec medecin_id = dr.kofi
PHASE 6 — Tests de régression
Cas	Action	Attendu
Reconnexion patient	Déconnexion + reconnexion	Pas de setup-profil, va direct /home
4ème mesure dans un créneau	Essayer d'enregistrer après 3 mesures	Erreur backend "déjà 3 mesures"
Jour 2 sans Jour 1 complet	(impossible normalement) Simuler via API avec jour=2	422 Unprocessable
QR invalide	Scanner un QR expiré	Bannière rouge "Validation en cours..."
Patient existant login	ama.koffi@bpmonitor.com / secret	Pas de setup (flag déjà potentiellement absent → vérifier)
Notes importantes
Créneaux : l'horloge utilisée est UTC. Lomé = GMT+0, donc heure locale = UTC. Pas de décalage à prévoir.
Chaque nouvelle session : la 1ère mesure crée automatiquement la session (pas besoin d'action préalable).
SMS : seront envoyés uniquement si afriksms_client_id est configuré dans le .env.
Le résumé de session est accessible via GET /api/v1/mesures/resume/{patient_id}/{session_id}.