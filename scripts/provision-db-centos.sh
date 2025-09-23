#!/bin/bash
set -e

echo "[1/5] Mise à jour du système..."
sudo dnf update -y

echo "[2/5] Installation MySQL..."
sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
sudo dnf install -y mysql-community-server

echo "[3/5] Démarrage MySQL..."
sudo systemctl enable --now mysqld

echo "[4/5] Configuration root MySQL..."
ROOT_PASS="R0ot!S3cur3#2025"

# Vérifier si root est déjà configuré
if mysql -uroot -p"$ROOT_PASS" -e ";" 2>/dev/null; then
    echo "Root déjà configuré, rien à faire."
else
    # Récupération mot de passe temporaire
    TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
    echo "Configuration root avec mot de passe temporaire..."
    mysql --connect-expired-password -uroot -p"$TEMP_PASS" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ROOT_PASS}';
FLUSH PRIVILEGES;
UNINSTALL COMPONENT 'file://component_validate_password';
SQL
fi

# Autoriser root depuis toutes les IP (pour connexion depuis l'hôte)
mysql -uroot -p"$ROOT_PASS" <<SQL
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

# Configurer MySQL pour écouter sur toutes les interfaces
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf
sudo systemctl restart mysqld

echo "[5/5] Création base et import SQL..."
DB_PATH="/vagrant/database"
DB_NAME="demo_db"

mysql -uroot -p"$ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

for sql_file in "$DB_PATH"/*.sql; do
    if [ -f "$sql_file" ]; then
        echo "Importation de $sql_file..."
        # Utiliser --force pour continuer même si des tables existent déjà
        mysql -uroot -p"$ROOT_PASS" "$DB_NAME" --force < "$sql_file"
    fi
done

echo "MySQL prêt avec la base '$DB_NAME'"
echo "Root password : $ROOT_PASS"
echo "Connexion depuis hôte : mysql -h 127.0.0.1 -P 3307 -uroot -p$ROOT_PASS $DB_NAME"
