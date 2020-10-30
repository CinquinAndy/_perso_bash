#!/bin/bash
# Cinquin Andy, B2C1
# Firewall IPTABLES - TP - Admin linux - BDD - log parse
while [ $valid ]
do
	clear
	echo "Quel est l'ip de la machine apache ?"
	read ipApache
	echo "Ip entrer : $ipApache"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
while [ $valid ]
do
	clear
	echo "Quel est l'utilisateur de la machine apache ?"
	read userApache
	echo "utilisateur entrer : $userApache"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
while [ $valid ]
do
	clear
	echo "Quel est le nom de la base de donnée ? (exemple : adventofcode)" 
	read nameBdd
	echo "nom entrer : $nameBdd"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
while [ $valid ]
do
	clear
	echo "Quel est le nom de l'utilisateur de base de donnée ? (exemple : root)" 
	read nameUserBdd
	echo "nom entrer : $nameUserBdd"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
while [ $valid ]
do
	clear
	echo "Quel est le mdp de la base de donnée ?" 
	read mdpBdd
	echo "utilisateur entrer : $mdpBdd"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
while [ $valid ]
do
	clear
	echo "Quel est la requete SQL que vous voulez récupéré et exporté en csv ? (exemple : select * from \\\`2015\\\`;)" 
	read requestBdd
	echo "requete entrer : $requestBdd"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
$requestBdd=$(echo $requestBdd | sed "s/\`/\\\`/g")
mysql -u $nameUserBdd -p"$mdpBdd" $nameBdd -e"$requestBdd" | sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" > exportbdd.csv
scp exportbdd.csv  $userApache@$ipApache:/home/$userApache/