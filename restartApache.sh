#!/bin/bash
# exec manually
# exec -> 5.2 / restart apache
systemctl restart sshd
systemctl restart vsftpd.service
systemctl restart apache2