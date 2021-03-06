#!/bin/bash
# exec by 2
# exec -> 3
echo "Bonjour, ce script va vous permettre d'installer apache et toutes les configurations nécessaires à son fonctionnement"

userApache=$1
userApachePass=$2
userBdd=$3
userBddIp=$4

apt install apache2 -y
apt install apache2-doc -y
systemctl start apache2
#on demande le nom de notre utilisateur
valid=true
while [ $valid ]
do
	clear
	echo "Quel sera le nom de votre site apache ?"
	read websiteName
	echo "Nom entrer : $websiteName"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
		if [ $validation == 'y' ] || [ $validation == 'Y' ];
		then
			break
		fi
done
clear

while [ $valid ]
do
	clear
	echo "Quel est le lien (url https) de votre repos git ?"
	read repo
	echo "Url entrer : $repo"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
		if [ $validation == 'y' ] || [ $validation == 'Y' ];
		then
			break
		fi
done
clear
dir=/var/www
if [[ ! -e $dir ]]
then
    mkdir /var/www
elif [[ ! -d $dir ]]
then
    echo "$dir existe déjà mais ce n'est pas un dossier"
else
    echo "$dir existe déjà"
fi
cd /var/www/
git clone $repo
cd /
repoName=$(echo $repo | sed -r 's/(\.git)$//' | sed 's/.*\///')
userIp=$(hostname -I)

echo "Nom validé : $websiteName"
echo "<VirtualHost *:80>
#ServerName $websiteName
ServerAdmin $userApache@localhost

ErrorLog /var/log/apache2/$websiteName.log
CustomLog /var/log/apache2/$websiteName.log combined

Redirect permanent / https://$userIp
</VirtualHost>" > /etc/apache2/sites-available/$websiteName.conf

echo "<VirtualHost *:443>
	#ServerName $websiteName

	ServerAdmin $userApache@localhost
	DocumentRoot /var/www/$repoName

	ErrorLog /var/log/apache2/$websiteName.log
	CustomLog /var/log/apache2/$websiteName.log combined

	SSLEngine on
	SSLCertificateFile /etc/ssl/certs/$websiteName.crt
	SSLCertificateKeyFile /etc/ssl/private/$websiteName.key
</VirtualHost>" > /etc/apache2/sites-available/$websiteName-ssl.conf

openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/$websiteName.crt -keyout /etc/ssl/private/$websiteName.key
chmod 440 /etc/ssl/private/$websiteName.key
a2enmod ssl
cd /var/www
a2dissite 000-default.conf
a2dissite default-ssl.conf
a2ensite $websiteName.conf
a2ensite $websiteName-ssl.conf

apt -y install lsb-release apt-transport-https ca-certificates 
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
apt update
apt -y install php7.4
apt-get -y install php7.4-{bcmath,bz2,intl,gd,mbstring,mysql,zip}
apt -y install mariadb-client
apt -y install php-mysql

clear

echo "entre ici ceci : "
rm -rf /home/$userApache/.ssh/id_ed25519
rm -rf /home/$userApache/.ssh/id_ed25519.pub
echo "/home/$userApache/.ssh/id_ed25519" | ssh-keygen -t ed25519
sed -i "s/root/$userApache/g" /home/$userApache/.ssh/id_ed25519.pub

chown $userApache:$userApache /home/$userApache/.ssh/id_ed25519
chown $userApache:$userApache /home/$userApache/.ssh/id_ed25519.pub

chmod 600 /home/$userApache/.ssh/id_ed25519
chmod 600 /home/$userApache/.ssh/id_ed25519.pub

sshApache=$(cat /home/$userApache/.ssh/id_ed25519.pub)
echo $sshApache
ssh $userBdd@$userBddIp "echo '$sshApache' >> /home/$userBdd/.ssh/authorized_keys"

echo "avant d'executer les restarts, finissez le script sur la machine mariadb"
echo "info --> ip de votre machine apache"
hostname -I
echo "(script apache terminé, veuillez executé le script 'restartApache.sh', après avoir fini les scripts mariadb , via /root/_perso_bash/restartApache.sh)"