#!/bin/bash
#
# Interrompe apenas os backups ativos
#
/bin/kill -9 $(ps aux | grep rsync | grep -v grep | grep "/atual/" | awk '{print $2}') 2>/dev/null

