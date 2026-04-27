#!/bin/bash
# BeforeInstall hook - stop existing web server if running

echo "BeforeInstall: stopping existing server..."
systemctl stop httpd 2>/dev/null || true
echo "BeforeInstall: done"
