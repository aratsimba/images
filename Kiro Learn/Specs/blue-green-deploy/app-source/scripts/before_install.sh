#!/bin/bash
# BeforeInstall hook - stop existing web server and clean target directory

echo "BeforeInstall: stopping existing server..."
systemctl stop httpd 2>/dev/null || true

echo "BeforeInstall: cleaning /var/www/html/ to avoid file-exists conflicts..."
rm -rf /var/www/html/*

echo "BeforeInstall: done"
