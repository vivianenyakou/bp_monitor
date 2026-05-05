## Tester le Swagger

---

### 1. Ouvrir le Swagger

```
http://localhost:8000/api/docs
```

---

### 2. Ordre de test recommandé

Suivez cet ordre car les données dépendent les unes des autres :

```
1. Vérifier le health check
2. Tester avec un patient existant (créé par le seed)
3. Créer des mesures
4. Obtenir le résumé
5. Vérifier les alertes
```

---

### Test 1 — Health check

```
GET /health
```
Cliquez **Try it out** → **Execute**

Résultat attendu :
```json
{
  "status": "ok",
  "service": "BP Monitor"
}
```

---

### Test 2 — Obtenir le profil patient

```
GET /api/v1/patients/{patient_id}
```
- `patient_id` = **1** (créé par le seed)

---

### Test 3 — Créer une mesure

```
POST /api/v1/mesures/
```

Copiez ce body :
```json
{
  "patient_id": 1,
  "systolique": 128,
  "diastolique": 82,
  "pouls": 72,
  "periode": "matin",
  "jour": 1,
  "numero_mesure": 1,
  "notes": "Après repos de 5 minutes",
  "session_id": "session-test-001"
}
```

Résultat attendu :
```json
{
  "id": 1,
  "patient_id": 1,
  "systolique": 128,
  "diastolique": 82,
  "categorie": "normale",
  "session_id": "session-test-001"
}
```

---

### Test 4 — Tester une tension critique

```
POST /api/v1/mesures/
```

```json
{
  "patient_id": 1,
  "systolique": 185,
  "diastolique": 115,
  "pouls": 95,
  "periode": "soir",
  "jour": 1,
  "numero_mesure": 1,
  "session_id": "session-test-001"
}
```

Résultat attendu :
```json
{
  "categorie": "critique"
}
```
Et une alerte doit être créée automatiquement en base.

---

### Test 5 — Lister les mesures du patient

```
GET /api/v1/mesures/patient/1
```

---

### Test 6 — Obtenir le résumé de session

```
GET /api/v1/mesures/resume/1/session-test-001
```

Résultat attendu :
```json
{
  "session_id": "session-test-001",
  "patient_id": 1,
  "nombre_mesures": 2,
  "session_complete": false,
  "progression": "2/18 mesures",
  "moyenne_globale": {
    "systolique": 156,
    "diastolique": 98,
    "categorie": "hypertension"
  }
}
```

---

### Test 7 — Acquitter une alerte

```
PATCH /api/v1/alertes/1/acquitter
```

```json
{
  "acquittee_par": "Dr Kofi Mensah"
}
```

---

### Vérifier directement en base

```bash
# Voir les mesures créées
docker-compose exec db psql -U bp_user -d bp_monitor \
  -c "SELECT id, systolique, diastolique, categorie, session_id FROM mesures;"

# Voir les alertes créées
docker-compose exec db psql -U bp_user -d bp_monitor \
  -c "SELECT id, niveau, statut, message FROM alertes;"
```

---

Dites-moi ce que vous voyez à chaque étape. 🚀