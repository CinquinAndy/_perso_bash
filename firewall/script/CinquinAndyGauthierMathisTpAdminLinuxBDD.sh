#!/bin/bash
# Cinquin Andy, B2C1
# Firewall IPTABLES - TP - Admin linux - BDD
IP="iptables"

echo "[paramètres : tous les ports ouvert de la machine]"
echo "[Liste de tous les paramètres passés dans le script --> ]"
for i in ${@}
do
    echo "ports : $i"
done

# on affiche toutes nos interfaces comme ceci
tailleTab=$(ip -br a | sed 's/ /%' | cut -d'%' -f1 | wc -l)
echo "nombre d'interface : $tailleTab"
declare -a TAB
i=0
for ligne in `ip -br a | sed 's/ /%' | cut -d'%' -f1`
do
    echo "ligne $i : $ligne"
    i++
done
$i=0

valid=true
while [ $valid ]
do
	echo "Quel est le numéro de l'interface où vous voulez ouvrir les ports passés en paramètres ?"
	read choixInterface
	echo "utilisateur sudo entrer : $choixInterface"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
clear
interface=$(ip -br a | sed 's/ /%' | cut -d'%' -f1 | sed -n "$choixInterface""p")

echo "interface choisie : $interface"
while [ $valid ]
do
	echo "Quel est le numéro de l'interface lan ?"
	read choixInterfaceLan
	echo "utilisateur sudo entrer : $choixInterfaceLan"
	echo "cela vous convient-il ? oui(y)/non(n)"
	read validation
	if [ ${validation^^} == 'Y' ]
	then
		break
	fi
done
interfaceLan=$(ip -br a | sed 's/ /%' | cut -d'%' -f1 | sed -n "$choixInterfaceLan""p")
echo "interface choisie : $interfaceLan"

### --: on reset tout
echo "[reset tables]"
${IP} -F
${IP} -X
${IP} -t nat -F
${IP} -t nat -X
${IP} -t mangle -F
${IP} -t mangle -X
${IP} -P INPUT ACCEPT
${IP} -P FORWARD ACCEPT
${IP} -P OUTPUT ACCEPT

# on met les regles pour l'interface loopback uniquement
echo "[accepts packets with local source ip adresses]"
${IP} -t mangle -A PREROUTING -s 224.0.0.0/3 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 169.254.0.0/16 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 172.16.0.0/12 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 192.0.2.0/24 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 192.168.0.0/16 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 10.0.0.0/8 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 0.0.0.0/8 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 240.0.0.0/5 -i $interfaceLan -j ACCEPT
${IP} -t mangle -A PREROUTING -s 127.0.0.0/8 -i $interfaceLan -j ACCEPT
# on bloque les ip privée pour notre interface qui sera face à internet, (on évite le spoofing)
${IP} -t mangle -A PREROUTING -s 224.0.0.0/3 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 169.254.0.0/16 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 172.16.0.0/12 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 192.0.2.0/24 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 192.168.0.0/16 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 10.0.0.0/8 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 0.0.0.0/8 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 240.0.0.0/5 -i $interface -j DROP
${IP} -t mangle -A PREROUTING -s 127.0.0.0/8 -i $interface -j DROP

### 0: règles de bases :
# Autoriser les flux en localhost
echo "[accept local]"
${IP} -A INPUT -i lo -j ACCEPT
# Autoriser les connexions déjà établies,
echo "[accept established / related]"
${IP} -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# on parcours nos différents ports et on configures nos règles
for i in ${@}
do
    while [ $valid ]
    do
        clear
        echo "$i -> udp(udp) ou tcp(tcp) ?"
        read choixUdpTcp
        echo "Choix : $choixUdpTcp"
	    echo "cela vous convient-il ? oui(y)/non(n)"
        read validation
        if [ ${validation^^} == 'Y' ]
        then
            break
        fi
    done
    while [ $valid ]
    do
        echo "$i -> Output (o) / Input (i) / Les deux (b) ?"
        read choixOutputInput
        if [ ${choixOutputInput^^} == 'O' ]
        then
            echo "Choix : Output"
        fi
        if [ ${choixOutputInput^^} == 'I' ]
        then
            echo "Choix : Input"
        fi
        if [ ${choixOutputInput^^} == 'B' ]
        then
            echo "Choix : Input & Output"
        fi
	    echo "cela vous convient-il ? oui(y)/non(n)"
        read validation
        if [ ${validation^^} == 'Y' ]
        then
            break
        fi
    done
    # On appliques les règles en fonction des saisies précédentes
    if [ ${choixUdpTcp^^} == 'TCP' ]
    then
        # dans le cas TCP ->
        if [ ${choixOutputInput^^} == 'I' ]
        then
            # dans le cas TCP + INPUT
            ${IPT} -A INPUT -p tcp -i $interface -m tcp --dport $i -j ACCEPT
            ${IPT} -A INPUT -p tcp -i $interface -m tcp --sport $i -j ACCEPT
        elif [ ${choixOutputInput^^} == 'O' ]
        then
            # dans le cas TCP + OUTPUT
            ${IPT} -A OUTPUT -p tcp -i $interface -m tcp --dport $i -j ACCEPT
            ${IPT} -A OUTPUT -p tcp -i $interface -m tcp --sport $i -j ACCEPT
        elif [ ${choixOutputInput^^} == 'B' ]
        then
            # dans le cas TCP + OUTPUT & INPUT
            ${IPT} -A INPUT -p tcp -i $interface -m tcp --dport $i -j ACCEPT
            ${IPT} -A INPUT -p tcp -i $interface -m tcp --sport $i -j ACCEPT
            ${IPT} -A OUTPUT -p tcp -i $interface -m tcp --dport $i -j ACCEPT
            ${IPT} -A OUTPUT -p tcp -i $interface -m tcp --sport $i -j ACCEPT
        fi
    elif [ ${choixUdpTcp^^} == 'UDP' ]
    then
        # dans le cas UDP ->
        if [ ${choixOutputInput^^} == 'I' ]
        then
            # dans le cas TCP + INPUT
            ${IPT} -A INPUT -p udp -i $interface -m udp --dport $i -j ACCEPT
            ${IPT} -A INPUT -p udp -i $interface -m udp --sport $i -j ACCEPT
        elif [ ${choixOutputInput^^} == 'O' ]
        then
            # dans le cas TCP + OUTPUT
            ${IPT} -A OUTPUT -p udp -i $interface -m udp --dport $i -j ACCEPT
            ${IPT} -A OUTPUT -p udp -i $interface -m udp --sport $i -j ACCEPT
        elif [ ${choixOutputInput^^} == 'B' ]
        then
            # dans le cas TCP + OUTPUT & INPUT
            ${IPT} -A INPUT -p udp -i $interface -m udp --dport $i -j ACCEPT
            ${IPT} -A INPUT -p udp -i $interface -m udp --sport $i -j ACCEPT
            ${IPT} -A OUTPUT -p udp -i $interface -m udp --dport $i -j ACCEPT
            ${IPT} -A OUTPUT -p udp -i $interface -m udp --sport $i -j ACCEPT
        fi
    fi
done

### Régles 'bonus'
### 1: Drop les paquets invalids, qui ne sont pas SYN et qui ne mene a aucune connexion tcp établie (established)### 
echo "[drop invalid packets]"
${IP} -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
### 2: Même principe que la première, mais la complète, dans certain cas, le première règle ne filtre pas tout, celle-c règle ce problème.
${IP} -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
### 3: Drop SYN les paquets syn qui sont ‘suspicieux’, avec des valeurs qui n’ont pas forcément de sens ou peux communes, aide à bloquer les attaques SYN stupides juste à base de spam ### 
${IP} -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
### 4: Bloque les paquets avec des TCP flags bizarres / bugués, les flags tcp légitimes n’utiliseront jamais ce genre de combinaisons
echo "[drop packets with suspiscious flags]"
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
${IP} -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
### 5: Limites les connexions TCP par secondes par IP source
${IP} -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
${IP} -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
### 6 : Protection contre le port scanning ###
echo "[block port scanning]"
${IP} -N port-scanning
${IP} -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
${IP} -A port-scanning -j DROP

# on drop les ips de digital ocean 
# ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0)(.*)$ -> utiliser pour récuperer la liste des ip uniquement à partir de "https://ipinfo.io/AS14061" 
# -> en remplaçant la chaine par uniquement le premier groupe de selection
${IP} -A INPUT -s 104.131.0.0/16 -j DROP
${IP} -A INPUT -s 104.236.0.0/16 -j DROP
${IP} -A INPUT -s 104.248.0.0/16 -j DROP
${IP} -A INPUT -s 107.170.0.0/16 -j DROP
${IP} -A INPUT -s 128.199.0.0/16 -j DROP
${IP} -A INPUT -s 138.68.0.0/16 -j DROP
${IP} -A INPUT -s 134.122.0.0/16 -j DROP
${IP} -A INPUT -s 138.197.0.0/16 -j DROP
${IP} -A INPUT -s 134.209.0.0/16 -j DROP

#Protection anti ddos
#Les utilisateurs effectuant un certain nombre de requêtes dans un intervalle de temps donné ("DoS") - avec iptables
${IP} -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 20/s --limit-burst 20 -j ACCEPT
${IP} -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

#Les utilisateurs effectuant un certain nombre de requêtes dans un intervalle de temps donné ("DoS") - avec fail2ban
ipaddr=$(hostname -I)
apt install fail2ban -y
echo "[DEFAULT]
ignoreip = 127.0.0.1/8 $ipaddr
bantime = 86400" > /etc/fail2ban/jail.local

# Les petits rigolos essayant de se connecter en SSH sur notre serveur Web
echo "[sshd]
enabled = true
port = ssh
filter = sshd
bantime = 3600
maxretry = 3
findtime = 600" >> /etc/fail2ban/jail.local

# on peux tester de simuler une attaque ddos avec 'nikto -h 192.168.43.193 -C all' par exemple
systemctl restart fail2ban

### on drop le reste - (on fini par ça)
${IP} -P INPUT -i $interface DROP

# Sauvegarde & persistance des tables 
apt install iptables-persistent -y
${IP}-save > /etc/iptables/rules.v4