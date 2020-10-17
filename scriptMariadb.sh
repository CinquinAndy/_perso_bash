#!/bin/bash
#exec by #3
echo "Bonjour, ce script va vous permettre d'installer MariaDB et toutes les configurations nécessaires à son fonctionnement"
userApache=$1
userApachePass=$2
userBdd=$3
userBddPass=$4
userBddIp=$5
userApacheIp=$6

apt install mariadb-server
clear
echo "repondez 'y' sur chaque réponse après votre mot de passe root de base de donnée"
/usr/bin/mysql_secure_installation

valid=true
while [ $valid ]
do
validation=true
clear
echo "Avez vous une base de donnée existante à importer et le script dans le systeme ? (y)oui"
read bddPresente
if [ $bddPresente == 'y' ] || [ $bddPresente == 'Y' ];
then
	while [ $validation ]
	do
		echo "Quel est le chemin vers la base de donnée ? (/data/script.sql)"
		read bddRoute
		echo "Nom entrer : $bddRoute"
		echo "cela vous convient-il ? y(oui)/n(non)"
		read validation
		if [ $validation == 'y' ] || [ $validation == 'Y' ];
		then
			break
		fi
	done
fi
done
clear

while [ $valid ]
do
	clear
echo "Quel est le nom de votre Base de donnée ?"
read bddName
echo "Nom entrer : $bddName"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "nom de site validé : $bddName"

while [ $valid ]
do
	clear
echo "Quel est le nom de votre utilisateur de Base de donnée ?"
read bddUserName
echo "Nom entrer : $bddUserName"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "nom d'utilisateur validé : $bddUserName"

while [ $valid ]
do
	clear
echo "Quel est le mdp de votre Base de donnée ?"
read bddUserPass
echo "Nom entrer : $bddUserPass"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "mot de passe utilisateur validé : $bddUserPass"

mysql -u="root" -p="$password" -e="CREATE DATABASE $bddName;
create user if not exists $bddUserName@$bddName identified by '$bddUserPass';"
mysql -u="root" -p="$password" < $bddRoute

ipaddr=$(hostname -I)
echo "[server]
[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
socket                  = /run/mysqld/mysqld.sock
port                    = 3306
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
bind-address            = $ipaddr
query_cache_size        = 16M
log_error = /var/log/mysql/error.log
expire_logs_days        = 10
ssl-ca=/etc/mysql/ssl/cacert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
character-set-server  = utf8mb4
collation-server      = utf8mb4_general_ci
[embedded]
[mariadb]
[mariadb-10.3]" > /etc/mysql/mariadb.conf.d/50-server.cnf

mysql -u="root" -p="$password" -e="use mysql;
update user set plugin='' where User='root';
flush privileges;"

echo "entre ici ceci : $(cat /home/$userBdd/.ssh/id_ed25519.pub)"
ssh-keygen -t ed25519
sshMariadb=$(cat /home/$userBdd/.ssh/id_ed25519.pub)
ssh $userApache@$userApacheIp sudo $sshMariadb >> /home/$userApache/.ssh/authorized_keys

clear
echo "script terminé, veuillez executé le script 'restart.sh' , via /home/$userBdd/restart.sh"