# Projet Infra Simple - Livrable

## Objectif
Déployer une infrastructure multi-machines avec Vagrant : Web Server (Ubuntu 22.04 + Nginx + site web) et Database Server (CentOS 9 + MySQL 8.0).

## Architecture
Utilisateur → Web Server (192.168.56.10) → Private Network → Database Server (192.168.56.20)

## Machines

**Web Server (Ubuntu)**  
- Nom : web-server  
- Services : Nginx, site web depuis ./website/  
- Dossier synchronisé : ./website/ → /var/www/html/  
- Port : 8080 (forwarded)  
- SSH disponible

**Database Server (CentOS)**  
- Nom : db-server  
- Services : MySQL 8.0  
- Base : demo_db  
- Table : users (id, nom, email, date_creation) avec données de démonstration  
- Port forwarding MySQL : 3306 → 3307 pour accès depuis l’hôte  

## Structure du projet
projet-infra-simple/  
├── Vagrantfile  
├── scripts/  
│   ├── provision-web-ubuntu.sh  
│   └── provision-db-centos.sh  
├── website/  
├── database/  
│   ├── create-table.sql  
│   └── insert-demo-data.sql  
└── README.md  

## Utilisation
1. Installer Vagrant et VirtualBox  
2. Lancer les machines : `vagrant up`  
3. Accéder au site web : http://192.168.56.10:8080  
4. Accéder à MySQL depuis l’hôte : `mysql -h 127.0.0.1 -P 3307 -uroot -pRootPass123! demo_db`

## Notes
- Mot de passe root MySQL : RootPass123!  
- Scripts configurent Nginx et MySQL automatiquement  
- SQL importé automatiquement depuis ./database/
