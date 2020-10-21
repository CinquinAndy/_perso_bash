#!/bin/bash
#exec #4
userBdd=$1
userBddPass=$2
userBddIp=$3

echo "Bonjour, ce script va vous permettre d'installer MariaDB et toutes les configurations nécessaires à son fonctionnement"

valid=true
while [ $valid ]
do
	clear
echo "avant de poursuivre ce script sur cette machine, terminé les deux scripts sur la machine apache, (executer scriptApache.sh)"
echo "info --> ip de votre machine mariadb"
hostname -I
echo "Quel est le nom de l'utilisateur sur la machine apache ?"
read userApache
echo "Nom entrer : $userApache"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "nom d'utilisateur validé : $userApache"

while [ $valid ]
do
	clear
echo "Quel est le mot de passe de votre utilisateur sur la machine apache ?"
read userApachePass
echo "Nom entrer : $userApachePass"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "nom de site validé : $userApachePass"

while [ $valid ]
do
	clear
echo "Quel est l'ip de la machine apache ?"
read userApacheIp
echo "Ip entrer : $userApacheIp"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "nom de site validé : $userApacheIp"

apt install mariadb-server -y
clear
echo "repondez 'y' sur chaque réponse après votre mot de passe root de base de donnée"
/usr/bin/mysql_secure_installation


bddPresente='x'
clear
echo "Avez vous une base de donnée existante à importer et le script dans le systeme ? (y)oui / (n)non"
read bddPresente
if [ $bddPresente == 'y' ] || [ $bddPresente == 'Y' ] || [ $bddPresente == 'N' ] || [ $bddPresente == 'n' ];
then
	while [ $valid ]
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
else
	echo "Ok, pas d'importation !"
fi
clear


while [ $valid ]
do
	clear
echo "Quel est le nom de la Base de donnée ?"
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
echo "Quel est le nom de l'utilisateur de la Base de donnée ?"
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
echo "Quel est le mdp de l'utilisateur de la Base de donnée ?"
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

while [ $valid ]
do
	clear
echo "Quel est le mdp de root de la Base de donnée ?"
read password
echo "Nom entrer : $password"
echo "cela vous convient-il ? y(oui)/n(non)"
read validation
if [ $validation == 'y' ] || [ $validation == 'Y' ];
then
	break
	fi
done
clear
echo "mot de passe root validé : $password"

mysql -u "root" -p="$password" -e "CREATE DATABASE \`$bddName\`;
create user if not exists '$bddUserName'@'%' identified by '$bddUserPass';
GRANT ALL PRIVILEGES ON *.* TO '$bddUserName'@'%';
flush privileges;"

if [ $bddPresente == 'y' ] || [ $bddPresente == 'Y' ];
then
	mysql -u "root" -p="$password" < $bddRoute
fi

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

mysql -u "root" -p="$password" -e "use \`mysql\`;
update \`user\` set plugin='' where \`User\`='root';
flush privileges;"

rm -rf /home/$userBdd/.ssh/id_ed25519
rm -rf /home/$userBdd/.ssh/id_ed25519.pub
echo "/home/$userBdd/.ssh/id_ed25519" | ssh-keygen -t ed25519
sed -i "s/root/$userBdd/g" /home/$userBdd/.ssh/id_ed25519.pub

chown $userBdd:$userBdd /home/$userBdd/.ssh/id_ed25519
chown $userBdd:$userBdd /home/$userBdd/.ssh/id_ed25519.pub

chmod 600 /home/$userBdd/.ssh/id_ed25519
chmod 600 /home/$userBdd/.ssh/id_ed25519.pub


sshMariadb=$(cat /home/$userBdd/.ssh/id_ed25519.pub)
echo $sshMariadb
ssh $userApache@$userApacheIp "echo '$sshMariadb' >> /home/$userApache/.ssh/authorized_keys"

echo "script terminé, veuillez executé le script 'restartMariadb.sh' , via /root/_perso_bash/$userBdd/restartMariadb.sh"