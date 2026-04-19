#!/bin/bash

function ctrl_c(){
  echo -e "[!] Saliendo..."
  exit 1
}

function checkPort(){
  (exec 3<> /dev/tcp/$1/$2) 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "[+] Host $1 - Port $2 (OPEN)"
  fi
  exec 3<&-
  exec 3>&-
}

# Ctrl+C
trap ctrl_c INT

if [ "$1" ]; then
  for port in $(seq 1 65535); do
    checkPort $1 $port &
  done; wait	
else
  echo "No se proporciono ip"
fi

