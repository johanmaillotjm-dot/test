#!/bin/bash
# ============================================================
#  Installation Docker + n8n — Zorin OS (Ubuntu/Debian base)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Variables configurables ---
N8N_PORT=5678
N8N_DATA_DIR="$HOME/n8n-data"
COMPOSE_FILE="$HOME/n8n/docker-compose.yml"

# ============================================================
# 0. Vérifications préliminaires
# ============================================================
info "Vérification des prérequis..."

[ "$EUID" -eq 0 ] && error "Ne pas exécuter ce script en root. Utilisez votre utilisateur normal."

if ! grep -qi "ubuntu\|debian\|zorin" /etc/os-release 2>/dev/null; then
    warn "Distribution non reconnue. Le script est prévu pour Zorin OS / Ubuntu / Debian."
fi

# ============================================================
# 1. Mise à jour du système
# ============================================================
info "Mise à jour du système..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

# ============================================================
# 2. Installation de Docker
# ============================================================
if command -v docker &>/dev/null; then
    info "Docker déjà installé : $(docker --version)"
else
    info "Installation de Docker..."

    # Dépendances
    sudo apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Clé GPG officielle Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Dépôt Docker (Zorin 17 = base Ubuntu 22.04 jammy)
    UBUNTU_CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-jammy}")
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    info "Docker installé : $(docker --version)"
fi

# ============================================================
# 3. Ajouter l'utilisateur au groupe docker
# ============================================================
if groups "$USER" | grep -q '\bdocker\b'; then
    info "Utilisateur '$USER' déjà dans le groupe docker."
else
    info "Ajout de '$USER' au groupe docker..."
    sudo usermod -aG docker "$USER"
    warn "Vous devrez vous reconnecter (ou lancer 'newgrp docker') pour que le groupe prenne effet."
fi

# ============================================================
# 4. Activer Docker au démarrage
# ============================================================
info "Activation du service Docker..."
sudo systemctl enable docker --quiet
sudo systemctl start docker

# ============================================================
# 5. Créer le dossier n8n et le docker-compose
# ============================================================
info "Création du dossier n8n : $HOME/n8n/"
mkdir -p "$HOME/n8n"
mkdir -p "$N8N_DATA_DIR"

cat > "$COMPOSE_FILE" <<EOF
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "${N8N_PORT}:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:${N8N_PORT}/
      - GENERIC_TIMEZONE=Europe/Paris
      - TZ=Europe/Paris
      # Décommentez pour activer l'authentification basique :
      # - N8N_BASIC_AUTH_ACTIVE=true
      # - N8N_BASIC_AUTH_USER=admin
      # - N8N_BASIC_AUTH_PASSWORD=motdepasse
    volumes:
      - ${N8N_DATA_DIR}:/home/node/.n8n
EOF

info "docker-compose.yml créé dans $HOME/n8n/"

# ============================================================
# 6. Lancer n8n
# ============================================================
info "Lancement de n8n..."
cd "$HOME/n8n"

# Utiliser newgrp si l'utilisateur vient d'être ajouté au groupe
if groups "$USER" | grep -q '\bdocker\b'; then
    docker compose up -d
else
    sudo docker compose up -d
fi

# ============================================================
# 7. Résumé
# ============================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Installation terminée !${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "  🌐 Interface n8n    : http://localhost:${N8N_PORT}"
echo -e "  📁 Données n8n      : ${N8N_DATA_DIR}"
echo -e "  📄 Compose file     : ${COMPOSE_FILE}"
echo ""
echo -e "  Commandes utiles :"
echo -e "    Arrêter n8n   → cd ~/n8n && docker compose down"
echo -e "    Redémarrer    → cd ~/n8n && docker compose restart"
echo -e "    Voir les logs → docker logs -f n8n"
echo -e "    Mettre à jour → cd ~/n8n && docker compose pull && docker compose up -d"
echo ""
if ! groups "$USER" | grep -q '\bdocker\b' 2>/dev/null; then
    warn "Reconnectez-vous pour utiliser docker sans sudo (groupe docker appliqué au prochain login)."
fi
echo ""
