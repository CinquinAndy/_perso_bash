#!/bin/bash
# exec manually
# exec -> 5.1 / restart mariadb
systemctl restart sshd
systemctl restart vsftpd.service
systemctl restart mariadb