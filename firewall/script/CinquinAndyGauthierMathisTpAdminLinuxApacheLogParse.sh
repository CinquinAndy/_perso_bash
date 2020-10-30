#!/bin/bash
# Cinquin Andy, B2C1
# Firewall IPTABLES - TP - Admin linux - APACHE - log

valid=true
while [ $valid ]
do
	clear
	echo "Quel est le chemin des logs de connexion apache ? (ex : /var/log/apache2/tutorataccess.log )"
	read cheminLog
	echo "utilisateur sudo entrer : $cheminLog"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done

# -> parsage des logs
# Les différentes adresses IP visitant notre site, ainsi que la fréquence de ces visites (i.e. le nombre de requêtes effectuées par ces IPs)
echo 'nbVisite,ipSource' > export.csv  | cat $cheminLog | awk -F '[ ]+' '/^/ {print $1}' | sort -r | uniq -c | sort -rn | sed 's/^[ ]*//' >> export.csv
# Les URLs visitées le plus souvent
echo 'nbVisite,adresseCible' > export.csv | cat $cheminLog | awk -F '["]+' '/ / {print $4}' | sort -n | uniq -c | egrep 'http' | sort -rn | sed 's/^[ ]*//' | sed 's/[ ]/,/g' >> export.csv