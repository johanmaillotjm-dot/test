#!/bin/bash
# ============================================================
#  Installation Homarr — Zorin OS (Ubuntu/Debian base)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Variables configurables ---
HOMARR_PORT=7575
HOMARR_DIR="$HOME/homarr"

# ============================================================
# 0. Vérifications
# ============================================================
info "Vérification des prérequis..."

[ "$EUID" -eq 0 ] && error "Ne pas exécuter en root. Utilisez votre utilisateur normal."

command -v docker &>/dev/null || error "Docker n'est pas installé. Lance d'abord le script install_docker_n8n.sh"

if ! groups "$USER" | grep -q '\bdocker\b'; then
    error "L'utilisateur '$USER' n'est pas dans le groupe docker. Lance 'newgrp docker' ou reconnecte-toi."
fi

# ============================================================
# 1. Créer les dossiers
# ============================================================
info "Création des dossiers Homarr..."
mkdir -p "$HOMARR_DIR"/{configs,icons,data}

# ============================================================
# 2. Créer le docker-compose.yml
# ============================================================
info "Création du docker-compose.yml..."
cat > "$HOMARR_DIR/docker-compose.yml" <<EOF
services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    restart: unless-stopped
    ports:
      - "${HOMARR_PORT}:7575"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${HOMARR_DIR}/configs:/app/data/configs
      - ${HOMARR_DIR}/icons:/app/public/icons
      - ${HOMARR_DIR}/data:/data
    environment:
      - TZ=Europe/Paris
EOF

info "docker-compose.yml créé dans $HOMARR_DIR/"

# ============================================================
# 3. Lancer Homarr
# ============================================================
info "Lancement de Homarr..."
cd "$HOMARR_DIR"
docker compose up -d

# ============================================================
# 4. Vérification
# ============================================================
info "Vérification du container..."
sleep 3

if docker ps | grep -q homarr; then
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}  Homarr installé et démarré !${NC}"
    echo -e "${GREEN}============================================================${NC}"
    echo ""
    echo -e "  🌐 Interface Homarr  : http://localhost:${HOMARR_PORT}"
    echo -e "  📁 Configs           : ${HOMARR_DIR}/configs"
    echo -e "  🖼️  Icônes            : ${HOMARR_DIR}/icons"
    echo -e "  💾 Données           : ${HOMARR_DIR}/data"
    echo ""
    echo -e "  Commandes utiles :"
    echo -e "    Arrêter    → cd ~/homarr && docker compose down"
    echo -e "    Redémarrer → cd ~/homarr && docker compose restart"
    echo -e "    Logs       → docker logs -f homarr"
    echo -e "    Màj        → cd ~/homarr && docker compose pull && docker compose up -d"
    echo ""
else
    error "Le container Homarr ne semble pas tourner. Vérifie avec : docker logs homarr"
fi
