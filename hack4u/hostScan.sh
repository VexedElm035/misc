#!/bin/bash

function ctrl_c(){
  echo -e "[!] Saliendo..."
  tput cnorm
  exit 1
}

# Ctrl+C
trap ctrl_c INT

tput civis #ocultar cursor

for i in $(seq 1 254); do
  timeout 1 bash -c "ping -c 1 192.168.1.$i &>/dev/null" && echo "HOST 192.168.1.$i ACTIVO" &
done; wait

tput cnorm #recuperar cursor
