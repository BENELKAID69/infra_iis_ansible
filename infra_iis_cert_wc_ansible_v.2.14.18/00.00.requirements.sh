#!/bin/bash
# ==============================================================================
# NOM DU SCRIPT : 00.00.requirements.sh
# CONFIGURATION : Alignement et durcissement des collections globales (System)
# AUTHOR        : Optimedit
# ==============================================================================

# --- CONFIGURATION DES COULEURS & CHEMINS ---
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[1;34m"
NC="\e[0m"

REQ_YML="00.00.requirements.yml"
SYS_PATH="/usr/share/ansible/collections"
TARGET_DIR="${SYS_PATH}/ansible_collections"

echo -e "${BLUE}🔍 [START] Vérification et alignement des collections Ansible globales...${NC}"

# 1. Vérification de la présence du fichier de référence
if [ ! -f "$REQ_YML" ]; then
    echo -e "${RED}❌ Erreur : Le fichier $REQ_YML est introuvable dans ce répertoire.${NC}"
    exit 1
fi

# 2. Extraction dynamique des versions cibles depuis le fichier YAML
TARGET_WIN_VER=$(grep -A 1 "name: ansible.windows" "$REQ_YML" | grep "version:" | awk '{print $2}' | tr -d '"'\''')
TARGET_COMM_VER=$(grep -A 1 "name: community.windows" "$REQ_YML" | grep "version:" | awk '{print $2}' | tr -d '"'\''')

echo -e "📋 Versions cibles définies dans le projet :"
echo -e "   - ansible.windows   : ${GREEN}${TARGET_WIN_VER}${NC}"
echo -e "   - community.windows : ${GREEN}${TARGET_COMM_VER}${NC}"
echo "------------------------------------------------------------"

# 3. Traitement et nettoyage de 'ansible.windows'
echo -e "${BLUE}🔄 Analyse de la collection 'ansible.windows'...${NC}"
if [ -d "${TARGET_DIR}/ansible.windows-${TARGET_WIN_VER}.info" ]; then
    echo -e "   ${GREEN}[OK] La version globale correspond exactement à la version attendue (${TARGET_WIN_VER}).${NC}"
else
    echo -e "   ${YELLOW}[WARN] Version incorrecte ou manquante détectée. Alignement en cours...${NC}"
    
    # Force l'installation de la version spécifiée par le fichier requirements
    sudo ansible-galaxy collection install -r "$REQ_YML" -p "$SYS_PATH" --force > /dev/null 2>&1
    
    # Recherche et suppression de tous les dossiers .info obsolètes qui ne correspondent pas à la cible
    find "$TARGET_DIR" -maxdepth 1 -type d -name "ansible.windows-*.info" ! -name "ansible.windows-${TARGET_WIN_VER}.info" | while read -r obsolete_dir; do
        echo -e "   ${RED}[CLEAN] Suppression du résidu obsolète : $(basename "$obsolete_dir")${NC}"
        sudo rm -rf "$obsolete_dir"
    done
fi

# 4. Traitement de 'community.windows'
echo -e "${BLUE}🔄 Analyse de la collection 'community.windows'...${NC}"
if [ -d "${TARGET_DIR}/community.windows-${TARGET_COMM_VER}.info" ]; then
    echo -e "   ${GREEN}[OK] La version globale correspond à la version attendue (${TARGET_COMM_VER}).${NC}"
else
    echo -e "   ${YELLOW}[WARN] Collection manquante ou obsolète. Installation de la version ${TARGET_COMM_VER}...${NC}"
    sudo ansible-galaxy collection install -r "$REQ_YML" -p "$SYS_PATH" --force > /dev/null 2>&1
fi

# 5. Sécurisation : Installation systématique de 'microsoft.ad' pour l'étape 01
echo -e "${BLUE}🔄 Analyse de la collection 'microsoft.ad'...${NC}"
if [ -d "${TARGET_DIR}/microsoft" ]; then
    echo -e "   ${GREEN}[OK] La collection microsoft.ad est déjà présente globalement.${NC}"
else
    echo -e "   ${YELLOW}[WARN] Collection microsoft.ad manquante. Installation globale...${NC}"
    sudo ansible-galaxy collection install microsoft.ad -p "$SYS_PATH" --force > /dev/null 2>&1
fi

echo "------------------------------------------------------------"
echo -e "${GREEN}✅ ALIGNEMENT DU SYSTEME TERMINE AVEC SUCCÈS !${NC}"
