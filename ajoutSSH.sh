#!/bin/bash
# exec manually
# exec -> 2
cd /
#on demande le nom de notre utilisateur
valid=true
while [ $valid ]
do
	clear
	echo "Quel sera le nom de votre utilisateur ?"
	read userApache
	echo "utilisateur sudo entrer : $userApache"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
	if [ $validation == 'y' ] || [ $validation == 'Y' ];
	then
		break
	fi
done
clear
echo "utilisateur validé : $userApache"

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
echo "utilisateur validé : $userApache"
echo "clé publique validée : $sshpubkey"

apt install vim -y
apt install openssh-server -y
apt install sudo -y
apt install git -y

echo "PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile      /home/$userApache/.ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server" > /etc/ssh/sshd_config

adduser $userApache sudo
mkdir /home/$userApache/.ssh
chown $userApache:$userApache /home/$userApache/.ssh
chmod 700 /home/$userApache/.ssh
echo $sshpubkey > /home/$userApache/.ssh/authorized_keys
chown $userApache:$userApache /home/$userApache/.ssh/authorized_keys
chmod 600 /home/$userApache/.ssh/authorized_keys

apt update -y
apt upgrade -y