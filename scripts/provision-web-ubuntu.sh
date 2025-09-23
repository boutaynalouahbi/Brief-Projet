#!/bin/bash
set -e

echo "[1/4] Mise à jour du système..."
sudo apt update -y
sudo apt upgrade -y

echo "[2/4] Installation de Nginx..."
sudo apt install -y nginx

echo "[3/4] Configuration Nginx..."
# S'assurer que le dossier web existe
sudo mkdir -p /var/www/html
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Activer le service Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "[4/4] Vérification..."
sudo systemctl status nginx | grep "active (running)" && echo "Nginx est en cours d'exécution"

echo "💻 Accès web depuis l'hôte : http://127.0.0.1:8080"
