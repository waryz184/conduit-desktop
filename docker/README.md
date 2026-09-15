# Conduit Desktop — Docker

## Deux profils de deploiement

### 🖥️ Profil `desktop` (recommande)

**Fonctionne aujourd'hui, sans modification du code.**

Build l'app Flutter pour Linux, la lance dans un ecran virtuel (Xvfb),
et la rend accessible depuis n'importe quel navigateur via noVNC.

→ Toutes les fonctionnalites sont conservees :
micro, haut-parleur, notifications, fichiers, etc.

```bash
docker compose -f docker/docker-compose.yml --profile desktop up -d --build
```

Puis ouvrir : http://localhost:6080/vnc.html
Mot de passe VNC : `conduit123` (variable d'env `VNC_PASSWORD`)

### 🌐 Profil `web` (en chantier)

Build la version Flutter Web + Nginx.

**⚠️ Necessite d'adapter le code** : Conduit utilise des plugins natifs
(flutter_inappwebview, flutter_secure_storage, vad, local_notifications…)
qui ne sont pas tous compatibles web. Voir `docs/WEB_BUILD.md` pour les
changements necessaires.

```bash
docker compose -f docker/docker-compose.yml --profile web up -d --build
```

Puis ouvrir : http://localhost:8080

---

## Utilisation

### Portainer

1. Dans Portainer, aller dans **Stacks** → **Add stack**
2. Copier le contenu de `docker/docker-compose.yml`
3. Modifier le profil si necessaire (par defaut `desktop`)
4. Deployer

### Docker Desktop

```bash
cd conduit-desktop
docker compose -f docker/docker-compose.yml --profile desktop up -d --build
```

### Variables d'environnement

| Variable | Defaut | Description |
|----------|--------|-------------|
| `VNC_PASSWORD` | `conduit123` | Mot de passe VNC |
| `DISPLAY_WIDTH` | `1280` | Largeur de l'ecran virtuel (pixels) |
| `DISPLAY_HEIGHT` | `800` | Hauteur de l'ecran virtuel (pixels) |

### Ports

| Port | Usage |
|------|-------|
| `6080` | noVNC — client web (ouvrir dans le navigateur) |
| `5900` | VNC — connexion directe (optionnel) |
| `8080` | Web — version Flutter Web (profil web seulement) |

### Persistance

Les configurations des serveurs, authentifications et preferences
sont stockees dans un volume Docker `conduit_data`.

---

## Structure

```
docker/
├── docker-compose.yml              # Composition des services
├── Dockerfile.vnc                  # Build Linux Desktop + noVNC  (✅ operationnel)
├── Dockerfile.web                  # Build Flutter Web + Nginx    (⚠️ code a adapter)
├── nginx/
│   └── conduit.conf                # Configuration Nginx
├── scripts/
│   ├── entrypoint-vnc.sh           # Demarrage Xvfb + noVNC + app
│   └── setup-web.sh                # Helper ajout plateforme web
└── README.md                       # Ce fichier
```