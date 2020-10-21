#!/bin/bash
# exec manually
# exec -> 1
echo "Bonjour, ce script va vous permettre d'installer les groupes sudoers, un utilisateur, sa clé ssh, un service ftp, et git, pour notre machine bdd"
#on demande le nom de notre utilisateur
valid=true
while [ $valid ]
do
	clear
	echo "Quel est le nom de votre utilisateur (machine mariadb) ?"
	read userMariadb
	echo "utilisateur entrer : $userMariadb"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
	if [ $validation == 'y' ] || [ $validation == 'Y' ];
	then
		break
	fi
done
clear
echo "utilisateur validé : $userMariadb"

# puis son mot de passe
while [ $valid ]
do
	clear
	echo "Quel sera le mot de passe de votre utilisateur ?"
	read userpass
	echo "mdp entrer : $userpass"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
	if [ $validation == 'y' ] || [ $validation == 'Y' ];
	then
		break
	fi
done
clear
echo "utilisateur validé : $userMariadb"
echo "utilisateur validé : $userpass"

# la clé ssh de la machine hote
while [ $valid ]
do
	clear
	echo "Quel est la clé ssh publique de votre machine hôte ?"
	read sshpubkey
	echo "clé ssh : $sshpubkey"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
	if [ $validation == 'y' ] || [ $validation == 'Y' ];
	then
		break
	fi
done
clear
echo "utilisateur validé : $userMariadb"
echo "utilisateur validé : $userpass"
echo "clé publique validée : $sshpubkey"

apt update -y
apt upgrade -y
apt install vim -y
apt install nano -y
apt install fish -y
apt install openssh-server -y
apt install sudo -y
apt install git -y
apt install vsftpd -y

if [ $(id -u) -eq 0 ]; then
	egrep "^$userMariadb" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$userMariadb existe déjà"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $userpass)
		useradd -m -p "$pass" "$userMariadb"
		[ $? -eq 0 ] && echo "L'utilisateur à été créer" || echo "Une erreur est survenue"
	fi
else
	echo "Il n'y a que root qui peux rajouté un utilisateur !"
exit 2
fi

echo "PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile      /home/$userMariadb/.ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server" > /etc/ssh/sshd_config

adduser $userMariadb sudo
mkdir /home/$userMariadb/.ssh
chown $userMariadb:$userMariadb /home/$userMariadb/.ssh
chmod 700 /home/$userMariadb/.ssh
echo $sshpubkey > /home/$userMariadb/.ssh/authorized_keys
chown $userMariadb:$userMariadb /home/$userMariadb/.ssh/authorized_keys
chmod 600 /home/$userMariadb/.ssh/authorized_keys

echo "Listen=NO
listen_ipv6=YES

anonymous_enable=NO
local_enable=YES

write_enable=YES

local_umask=022

dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES

secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO

allow_writeable_chroot=YES" > /etc/vsftpd.conf

userBddIp=$(hostname -I)
bash /root/_perso_bash/scriptMariadb.sh $userBdd $userpass $userBddIp