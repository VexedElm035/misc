#!/bin/bash

# Define color variables
redColour="\\e[0;31m\\033[1m"
greenColour="\\e[0;32m\\033[1m"
blueColour="\\e[0;34m\\033[1m"
noColour="\\e[0m\\033[1m" # No Color (resets the terminal to default)

# Variable globales
main_url="https://htbmachines.github.io/bundle.js"
main_file="$(echo $main_url | rev |  cut -d '/' -f 1 | rev)"
md5_file=$(md5sum $main_file 2>/dev/null | awk '{print $1}')
md5_update=$(curl -s -X GET https://htbmachines.github.io/bundle.js | js-beautify | md5sum | awk '{print $1}')

function ctrl_c(){
  printf %b "\n\n${redColour}[!] Saliendo...${endColour}\n"
  tput cnorm && exit 1
}

function helpPanel(){
  echo -e "\n[?] Uso:"
  printf %b "\t${greenColour}u) ${noColour}Descargar o actualizar archivos necesarios\n"
  printf %b "\t${greenColour}m) ${noColour}Buscar por un nombre de maquina\n"
  printf %b "\t${greenColour}i) ${noColour}Buscar por direccion IP\n"
  printf %b "\t${greenColour}d) ${noColour}Buscar por dificultad\n"
  printf %b "\t${greenColour}o) ${noColour}Buscar por sistema operativo\n"
  printf %b "\t${greenColour}s) ${noColour}Buscar por skill\n"
  printf %b "\t${greenColour}y) ${noColour}Obtener enlace de walktrought\n"
  printf %b "\t${greenColour}h) ${noColour}Mostrar este panel de ayuda\n"
}

function searchMachine(){
  machine_name="$1"
  machine_check="$(cat bundle.js | awk "/name: \"${machine_name}\"/,/}];|}),/" | grep -vE "id:|sku:|resuelta:|lf.push" | tr -d '"' | tr -d ',' | sed 's/^ *//')"
  if [ "$machine_check" ]; then
    printf %b "\n${greenColour}[+]${noColour} Listando propiedades de la maquina${blueColour} $machine_name${noColour}:\n\n"
    printf %b "$machine_check\n\n"
  else
    printf %b "${redColour}\n[!] La maquina ${blueColour}${machine_name}${redColour} no fue encontrada${noColour}\n\n"
  fi
}

function updateFiles(){
  echo -e "\n[!] Verificando integridad de archivos y actualizaciones...\n"
  tput civis
  sleep 2
  if [[ ! -f $main_file || ! "$md5_file" == "$md5_update" ]]; then
    printf %b "[+] Descargando archivos necesarios..."
    curl -s $main_url > $main_file
    $(js-beautify $main_file | tee "$main_file.temp" && mv "$main_file.temp" $main_file) &>/dev/null
    printf %b "\n${greenColour}[+] ${noColour}Todos los archivos fueron verificados y actualizados\n\n"
    tput cnorm
  else
    printf %b "${redColour}[!] ${noColour}No hay actualizaciones disponibles...\n\n"
  fi
}

function searchIp(){
  ip_address="$1"
  machine_name="$(cat $main_file | grep "ip: \"$ip_address\"" -B 5 | grep "name: " | awk '{print $NF}' | tr -d '"' | tr -d ',')"
  
  if [ "$machine_name" ]; then
    printf %b "\n${greenColour}[+]${noColour} La ip: ${blueColour}$ip_address ${noColour}pertenece a ${blueColour}$machine_name${noColour}\n"
    searchMachine $machine_name
  else
    printf %b "${redColour}\n[!] La maquina con direccion IP ${blueColour}${ip_address}${redColour} no fue encontrada${noColour}\n\n"
  fi
}

function getWT(){
  machine_name="$1"
  machine_wt="$(cat $main_file | awk "/name: \"$machine_name\"/,/}];|}),/" | grep -vE "id:|sku:|resuelta:|lf.push" | tr -d '"' | tr -d ',' | sed 's/^ *//' | grep youtube | awk '{print $NF}')"
  
  if [ "$machine_wt" ]; then
    printf %b "\n${greenColour}[+]${noColour} El walkthrought de la maquina${blueColour} $machine_name ${noColour}esta en el siguiente enlace:${blueColour} $machine_wt ${noColour}\n\n"
  else
    printf %b "${redColour}\n[!] La maquina ${blueColour}${machine_name}${redColour} no fue encontrada${noColour}\n\n"
  fi
}

function searchByDifficulty(){
  difficulty="$1"
  difficulty_results="$(cat $main_file | grep "dificultad: \"$difficulty\"" -B 5 | grep "name: " | awk '{print $NF}' | tr -d '"' | tr -d ',')"
  if [ "$difficulty_results" ]; then
    printf %b "\n${greenColour}[+]${noColour} Las maquinas con dificultad $difficulty son las siguientes: \n\n"
    echo -e "$difficulty_results" | column
  else
    printf %b "${redColour}\n[!] No se encontraron maquinas de dificultad ${blueColour}${difficulty}${noColour}\n\n"
  fi
}

function searchByOS(){
  os="$1"
  os_results="$(cat ${main_file} | grep "so: \"${os}\"" -B 5 | grep "name: " | awk '{print $NF}' | tr -d '"' | tr -d ",")" 
  if [ "$os_results" ]; then
     printf %b "\n${greenColour}[+]${noColour} Las maquinas con sistema operativo $os son las siguientes: \n\n"
    echo -e "$os_results" | column
  else
    printf %b "${redColour}\n[!] No se encontraron maquinas con sistema operativo ${blueColour}${os}${noColour}\n\n"
  fi
}

function getOsDifficulty(){
  difficulty="$1"
  os="$2"
  results="$(cat $main_file | grep "so: \"${os}\"" -C 5 | grep "dificultad: \"${difficulty}\"" -B 5 | grep "name: " | awk '{print $NF}' | tr -d '"' | tr -d "," | column
)" 
  if [ "$results" ]; then
     printf %b "\n${greenColour}[+]${noColour} Las maquinas con sistema operativo $os y dificultad ${difficulty} son las siguientes: \n\n"
    echo -e "$results" | column
  else
    printf %b "${redColour}\n[!] No se encontraron maquinas con sistema operativo ${blueColour}${os}${noColour} y dificultad ${difficulty}\n\n"
  fi
}

function searchBySkill(){
  skill="$1"
  skill_results="$(cat $main_file | grep "skills: " -B 7 | grep -i "${skill}" -B 7 | grep "name: " | awk '{print $NF}' | tr -d '"' | tr -d ',')"
  if [ "$skill_results" ]; then
     printf %b "\n${greenColour}[+]${noColour} Las maquinas con skills de tipo $skill son las siguientes: \n\n"
    echo -e "$skill_results" | column
  else
    printf %b "${redColour}\n[!] No se encontraron maquinas con la skill ${blueColour}${os}${noColour}\n\n"
  fi
}
  
#Ctrl+C
trap ctrl_c INT

# Indicadores
declare -i arg_counter=0

# Chivatos
declare -i chivato_difficulty=0
declare -i chivato_os=0

while getopts "m:ui:y:d:o:s:h" arg; do
  case $arg in
    m) machine_name="$OPTARG"; let arg_counter+=1;;
    u) let arg_counter+=2;;
    i) ip_address="$OPTARG"; let arg_counter+=3;;
    y) machine_name="$OPTARG"; let arg_counter+=4;;
    d) difficulty="$OPTARG"; chivato_difficulty=1; let arg_counter+=5;;
    o) os="$OPTARG"; chivato_os=1; let arg_counter+=6;;
    s) skill="$OPTARG"; let arg_counter+=7;;
    h) ;;
  esac
done

if [ $arg_counter -eq 1 ]; then
  searchMachine $machine_name
elif [ $arg_counter -eq 2 ]; then
  updateFiles
elif [ $arg_counter -eq 3 ]; then
  searchIp $ip_address
elif [ $arg_counter -eq 4 ]; then
  getWT $machine_name
elif [ $arg_counter -eq 5 ]; then
  searchByDifficulty $difficulty
elif [ $arg_counter -eq 6 ]; then
  searchByOS $os
elif [ $chivato_difficulty -eq 1 ] && [ $chivato_os -eq 1 ] ; then
  getOsDifficulty $difficulty $os
elif [ $arg_counter -eq 7 ]; then
  searchBySkill "$skill"
else
  helpPanel
fi

