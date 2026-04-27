#!/bin/bash
# AfterInstall hook - set permissions and start the web server

echo "AfterInstall: setting permissions..."
chmod -R 755 /var/www/html
chown -R apache:apache /var/www/html

echo "AfterInstall: starting httpd..."
systemctl start httpd
systemctl enable httpd
echo "AfterInstall: done"
