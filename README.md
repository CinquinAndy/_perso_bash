# _perso_bash
script bash install - on se facilite la vie  
  
On créer 2 VM, sur les deux on installe openssh (de base)  
& git  
-> on peux aussi installer console-data pour changer la config clavier dans la vm, pour les copiers/coller de vmWareWorkstation
  
sur les deux on clone _perso_bash (dans cd /root/), (ou 'cd ~')

soit on configure nos vm dans vmWareWorkstation, soit  
on se connecte en root, en ssh, via un terminal plus sympa que la vm  
  
on execute scriptSSHMariadb.sh , sur la machine mariadb,  
on execute scriptSSHApache.sh , sur la machine apache  

Puis on suis les indications  
on execute restartApache.sh , sur la machine apache  
on execute restartMariadb.sh , sur la machine mariadb  
  
Cadeau un tuto pour l'utilisé :D ♥  
https://youtu.be/ishTzMWHEBs