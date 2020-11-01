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

# puis son mot de passe
while [ $valid ]
do
	clear
	echo "Quel sera le mot de passe de votre utilisateur ?"
	read userPass
	echo "mdp entrer : $userPass"
	echo "cela vous convient-il ? y(oui)/n(non)"
	read validation
	if [ $validation == 'y' ] || [ $validation == 'Y' ];
	then
		break
	fi
done
clear
echo "utilisateur validé : $userApache"
echo "utilisateur validé : $userPass"

apt update -y
apt upgrade -y
apt install vim -y
apt install openssh-server -y
apt install sudo -y
apt install git -y

if [ $(id -u) -eq 0 ]; then
	egrep "^$userApache" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$userApache existe déjà !"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $userPass)
		useradd -m -p "$pass" "$userApache" --shell /bin/bash
		[ $? -eq 0 ] && echo "L'utilisateur à été créer" || echo "Une erreur est survenue"
	fi
else
	echo "Il y a que root qui peux ajouté un utilisateur au systeme"
exit 2
fi