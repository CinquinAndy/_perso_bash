#!/bin/bash
# Cinquin Andy, B2C1
# Firewall IPTABLES
IPT="iptables"
# Exercice 4 & 5, les règles que j’ai utilisées.
### --: on reset tout
echo "[reset tables]"
${IPT} -F
${IPT} -X
${IPT} -t nat -F
${IPT} -t nat -X
${IPT} -t mangle -F
${IPT} -t mangle -X
${IPT} -P INPUT ACCEPT
${IPT} -P FORWARD ACCEPT
${IPT} -P OUTPUT ACCEPT

### 0: règles de bases :
# Autoriser les flux en localhost
echo "[accept local]"
${IPT} -A INPUT -i lo -j ACCEPT
# Autoriser les connexions déjà établies,
echo "[accept established / related]"
${IPT} -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Autoriser la connexion SSH
echo "[accept ssh]"
${IPT} -A INPUT -p tcp -m tcp -m conntrack --ctstate NEW,ESTABLISHED --dport 22 -j ACCEPT
${IPT} -A OUTPUT -p tcp -m tcp -m conntrack --ctstate NEW,ESTABLISHED --sport 22 -j ACCEPT

# Autoriser HTTP, notre machine accepte les connexions http
echo "[accept http]"
${IPT} -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
${IPT} -A INPUT -p tcp -m tcp --sport 80 -j ACCEPT

# Autoriser HTTPS, notre machine accepte les connexions https
echo "[accept https]"
${IPT} -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
${IPT} -A INPUT -p tcp -m tcp --sport 443 -j ACCEPT

# Autoriser DNS, on accepte les connexion dns , mais on a besoin de donner une réponse sur ce même port, donc on autorise aussi l'output
echo "[accept dns]"
${IPT} -A INPUT -p udp -m udp --dport 53 -j ACCEPT
${IPT} -A INPUT -p udp -m udp --sport 53 -j ACCEPT
${IPT} -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
${IPT} -A OUTPUT -p udp -m udp --sport 53 -j ACCEPT

## exercice 4 - On limite le nombre de ping avec hashlimit
## on met la limite sur le port icmp (ping), de 2 par seconde, par ip (dstip / srcip , destination ip et source ip) et on lui donne un nom
echo "[config icmp dos protection]"
${IPT} -N LOGICMP
${IPT} -A INPUT -p icmp -j LOGICMP
${IPT} -A LOGICMP -p icmp -m hashlimit --hashlimit 2/sec --hashlimit-mode dstip,srcip --hashlimit-name anti_ping_dos -j ACCEPT
# exercice 5 - on log les pings qui sont passés
${IPT} -A LOGICMP -p icmp -j LOG --log-prefix "iptables drop requests " --log-level warning
# puis on drop le tout après avoir
${IPT} -A OUTPUT -p icmp -j ACCEPT
${IPT} -A LOGICMP -j DROP

# Les règles de filtrage par nombre de ping sont utiles seulement dans le cas où nous avons besoin d’avoir ce protocole autorisé, et qu’on en as l’utilité, usuellement, on n’en a pas besoin dans la plupart des cas.
# il faudra donc tout simplement drop le protocole ICMP (voir la partie 6 dans la suite des règles )
# Politique par défaut de la table INPUT : DROP. (Bloquer tout le reste).
#${IPT} -P FORWARD DROP 
# Si on n’est pas un routeur ou un NAT pour un réseau privé, on ne forward pas de paquet.
# Après avoir mit en places ces règles nous pouvons peaufiner tout ça et empêché tout un paquet d’autre attaque DOS, 
# Voici les règles utilisées pour complétés tout cela, 
# En utilisant plusieurs sources croisés (voir annexes)
# Règles bonus : 
### 1: Drop les paquets invalids, qui ne sont pas SYN et qui ne mene a aucune connexion tcp établie (established)### 
echo "[drop invalid packets]"
${IPT} -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

### 2: Même principe que la première, mais la complète, dans certain cas, le première règle ne filtre pas tout, celle-c règle ce problème.
${IPT} -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

### 3: Drop SYN les paquets syn qui sont ‘suspicieux’, avec des valeurs qui n’ont pas forcément de sens ou peux communes, aide à bloquer les attaques SYN stupides juste à base de spam ### 
${IPT} -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

### 4: Bloque les paquets avec des TCP flags bizarres / bugués, les flags tcp légitimes n’utiliseront jamais ce genre de combinaisons
echo "[drop packets with suspiscious flags]"
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
${IPT} -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

### 5: bloques les connexions d’ip interne / (spoofing ? ) ### -> attention a pas vous empêchez votre propre connexion si vous êtes sur une vm
echo "[drop packets with local source ip adresses]"
${IPT} -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP
${IPT} -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
${IPT} -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
#${IPT} -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
#${IPT} -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP
${IPT} -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
${IPT} -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
${IPT} -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
${IPT} -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP

### 6: Drop ICMP (en général on en as pas besoin) ### 
echo "[drop icmp (classic)]"
${IPT} -t mangle -A PREROUTING -p icmp -j DROP
### 7: Bloques les paquets fragmentés, normalement on en as pas besoins, et les bloqués vont répartir la charges lords d’un spam udp 
# (udp fragmentation flood), mais la plupart du temps, les attaques de ce types utilises le nombre de requête pour mettre à genou notre carte réseau,
# cette règle est donc pas forcément utile et relativement optionnelle
${IPT} -t mangle -A PREROUTING -f -j DROP

### 8: Limites les connexions par ip ### 
echo "[others rules]"
${IPT} -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset

### 9: Limites les paquets RST ###
${IPT} -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
${IPT} -A INPUT -p tcp --tcp-flags RST RST -j DROP

### 10: Limites les connexions TCP par secondes par IP source
${IPT} -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
${IPT} -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

### 11 : SSH protection anti brute-force ###
${IPT} -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set
${IPT} -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP


### Protection contre le port scanning ###
echo "[block port scanning]"
${IPT} -N port-scanning
${IPT} -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
${IPT} -A port-scanning -j DROP

# tout ceci couplés avec des paramètres différents de configurations de kernel linux, dans /etc/sysctl.conf 
# (puis faire la commande 'sysctl -p' pour appliqués les paramètres)
# Voici les sources utilisées pour toutes les infos précédentes. 
# https://javapipe.com/blog/iptables-ddos-protection/
# https://inetdoc.net/guides/iptables-tutorial/
# https://stackoverflow.com/questions/27173562/iptables-limit-the-number-of-logged-packets-second
# http://dennisk.freeshell.org/cis240dl_ping_flood.mkd.html
# https://geekeries.org/2017/12/configuration-avancee-du-firewall-iptables/?cn-reloaded=1

### on drop le reste
${IPT} -P INPUT DROP