#!/bin/bash

# ==============================================================================
# NOM DU SCRIPT : add_new_ansible_admin.sh
# DESCRIPTION   : Ajout rapide d'un nouvel administrateur dans l'infra existante
#                 sans réinstallation. Configuration Sudo, Bashrc et Droits Git.
# EXECUTION     : À lancer en tant que root (ou avec sudo)
# USAGE         : sudo ./add_new_ansible_admin.sh
# ==============================================================================

# --- CONFIGURATION DES VARIABLES ---
BASE_DIR="/projet_optimedit"
ADMIN_GROUP="gr_ansible_admins"

# Vérification que le script est exécuté en root/sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Erreur : Ce script doit être exécuté en tant que root ou avec sudo."
    exit 1
fi

echo "------------------------------------------------------------"
echo " 🚀 AJOUT D'UN NOUVEL ADMINISTRATEUR INFRASTRUCTURE"
echo "------------------------------------------------------------"

# --- INTERACTION : SAISIE DES PARAMÈTRES ---
# Saisie du nom de l'utilisateur
read -p "👉 Entrez le NOM du nouvel utilisateur : " NEW_USER

if [ -z "$NEW_USER" ]; then
    echo "❌ Erreur : Le nom d'utilisateur ne peut pas être vide."
    exit 1
fi

# Saisie sécurisée du mot de passe (les caractères ne s'affichent pas)
echo -n "👉 Entrez le MOT DE PASSE pour $NEW_USER : "
read -s NEW_PASS
echo "" # Retour à la ligne après la saisie masquée

if [ -z "$NEW_PASS" ]; then
    echo "❌ Erreur : Le mot de passe ne peut pas être vide."
    exit 1
fi

echo "------------------------------------------------------------"
echo "Configuration en cours pour l'utilisateur '$NEW_USER'..."
echo "------------------------------------------------------------"

# --- 1. CRÉATION ET CONFIGURATION DU COMPTE LOCAL ---
if id "$NEW_USER" &>/dev/null; then
    echo "ℹ️  [INFO] L'utilisateur local '$NEW_USER' existe déjà."
else
    useradd -m -s /bin/bash "$NEW_USER"
    echo "$NEW_USER:$NEW_PASS" | chpasswd
    echo "✅ [OK] Utilisateur local '$NEW_USER' créé avec le mot de passe saisi."
fi

# Raccordement aux groupes (Sudo système + Groupe collaboratif Ansible)
usermod -aG sudo,${ADMIN_GROUP} "$NEW_USER"
echo "✅ [OK] Utilisateur '$NEW_USER' ajouté aux groupes 'sudo' et '$ADMIN_GROUP'."

# --- 2. CONFIGURATION DE L'ENVIRONNEMENT ANSIBLE (.bashrc) ---
BASHRC_FILE="/home/$NEW_USER/.bashrc"
if [ -f "$BASHRC_FILE" ]; then
    if ! grep -q "ANSIBLE_NET_USER" "$BASHRC_FILE"; then
        echo -e "\n# Configuration de l'identité utilisateur pour l'orchestration Ansible" >> "$BASHRC_FILE"
        echo "export ANSIBLE_NET_USER=\"$NEW_USER\"" >> "$BASHRC_FILE"
        chown $NEW_USER:$NEW_USER "$BASHRC_FILE"
        echo "✅ [OK] Variable ANSIBLE_NET_USER='$NEW_USER' injectée dans son .bashrc."
    else
        echo "ℹ️  [INFO] La variable ANSIBLE_NET_USER est déjà présente dans son .bashrc."
    fi
fi

# --- 3. HARMONISATION ET PERSISTANCE DES DROITS SUR LE DOSSIER PROJET ---
echo "🔐 [CHMOD] Application des droits collaboratifs sur $BASE_DIR..."

# Réalignement du groupe sur l'ensemble de l'arborescence pour inclure le nouvel utilisateur
chown -R :$ADMIN_GROUP $BASE_DIR

# Rappel des droits d'écriture et du bit SGID (le "s") pour l'héritage collaboratif
find $BASE_DIR -type d -exec chmod g+s {} +
find $BASE_DIR -type d -exec chmod g+rwX {} +
find $BASE_DIR -type f -exec chmod g+rw {} +

# Rendre tous les scripts d'audits ou outils .sh directement exécutables par le nouvel admin
find $BASE_DIR -name "*.sh" -exec chmod ug+x {} +

echo "✅ [OK] Droits d'accès et d'exécution mis à jour sur l'arborescence."
echo "------------------------------------------------------------"
echo "🎉 L'utilisateur '$NEW_USER' est maintenant opérationnel et configuré !"
echo "👉 Pour tester : su - $NEW_USER"
echo "------------------------------------------------------------"
