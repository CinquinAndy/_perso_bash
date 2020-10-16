#!/bin/bash
# exec -> 5 / restart apache
systemctl restart sshd
systemctl restart vsftpd.service
systemctl restart apache2