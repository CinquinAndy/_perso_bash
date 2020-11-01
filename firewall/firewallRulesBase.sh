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

### règles de bases :
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
${IPT} -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT
${IPT} -A OUTPUT -p tcp -m tcp --sport 80 -j ACCEPT

# Autoriser HTTPS, notre machine accepte les connexions https
echo "[accept https]"
${IPT} -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
${IPT} -A INPUT -p tcp -m tcp --sport 443 -j ACCEPT
${IPT} -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
${IPT} -A OUTPUT -p tcp -m tcp --sport 443 -j ACCEPT

# Autoriser le port de mariadb
echo "[accept mariadb]"
${IPT} -A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
${IPT} -A INPUT -p tcp -m tcp --sport 3306 -j ACCEPT

# Autoriser DNS, on accepte les connexion dns , mais on a besoin de donner une réponse sur ce même port, donc on autorise aussi l'output
echo "[accept dns]"
${IPT} -A INPUT -p udp -m udp --dport 53 -j ACCEPT
${IPT} -A INPUT -p udp -m udp --sport 53 -j ACCEPT
${IPT} -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
${IPT} -A OUTPUT -p udp -m udp --sport 53 -j ACCEPT

# Règles bonus : 
### Drop les paquets invalids, qui ne sont pas SYN et qui ne mene a aucune connexion tcp établie (established)### 
echo "[drop invalid packets]"
${IPT} -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

### Même principe que la première, mais la complète, dans certain cas, le première règle ne filtre pas tout, celle-c règle ce problème.
${IPT} -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

### Drop SYN les paquets syn qui sont ‘suspicieux’, avec des valeurs qui n’ont pas forcément de sens ou peux communes, aide à bloquer les attaques SYN stupides juste à base de spam ### 
${IPT} -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

### Bloque les paquets avec des TCP flags bizarres / bugués, les flags tcp légitimes n’utiliseront jamais ce genre de combinaisons
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

### Drop ICMP (en général on en as pas besoin) ### 
echo "[drop icmp (classic)]"
${IPT} -t mangle -A PREROUTING -p icmp -j DROP
### Bloques les paquets fragmentés, normalement on en as pas besoins, et les bloqués vont répartir la charges lords d’un spam udp 
# (udp fragmentation flood), mais la plupart du temps, les attaques de ce types utilises le nombre de requête pour mettre à genou notre carte réseau,
# cette règle est donc pas forcément utile et relativement optionnelle
${IPT} -t mangle -A PREROUTING -f -j DROP

### Limites les connexions par ip ### 
echo "[others rules]"
${IPT} -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset

### Limites les paquets RST ###
${IPT} -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
${IPT} -A INPUT -p tcp --tcp-flags RST RST -j DROP

### Limites les connexions TCP par secondes par IP source
${IPT} -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
${IPT} -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

### SSH protection anti brute-force ###
${IPT} -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set
${IPT} -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP

### Protection contre le port scanning ###
echo "[block port scanning]"
${IPT} -N port-scanning
${IPT} -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
${IPT} -A port-scanning -j DROP

### on drop le reste
${IPT} -P INPUT DROP

apt install iptables-persistent -y
${IPT}-save > /etc/iptables/rules.v4