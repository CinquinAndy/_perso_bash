# _perso_bash
script bash install - on se facilite la vie

On créer 2 VM, sur les deux on installe openssh (de base)
& git

sur les deux on clone le projet
on se connecte en root, en ssh, via un terminal plus sympa que la vm

on execute scriptSSHMariadb.sh , sur la machine mariadb
on execute scriptSSHApache.sh , sur la machine apache
( le deuxieme executera scriptApache.sh & scriptMariadb.sh automatiquement)
on execute restartApache.sh , sur la machine apache
on execute restartMariadb.sh , sur la machine mariadb
