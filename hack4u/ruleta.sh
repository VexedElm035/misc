#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c(){
  printf %b "\n\n${redColour}[!] Saliendo...${endColour}\n"
  tput cnorm; exit 1
}

function helpPanel(){
  printf %b "\n${yellowColour}[?]${endColour} Uso: ${purpleColour}$0${endColour}\n"
  printf %b "\t${purpleColour}-m${endColour}) Dinero con el que se desea jugar\n"
  printf %b "\t${purpleColour}-t${endColour}) Tecnica con la que se desea jugar:\n \t\t${blueColour}mg${endColour}=MartinGala\n\t\t${blueColour}iv${endColour}=inverseLabrouchere\n"
  printf %b "\t${purpleColour}-h${endColour}) Mostrar este panel de ayuda\n"
  exit 1
}

function martinGala(){
  play_counter=1

  loss_streak=""
  top_money=$money

  printf %b "\n${yellowColour}[+]${endColour} Dinero actual: ${greenColour}\$$money${endColour}\n"
  printf %b "${yellowColour}[+]${endColour} Cuanto dinero quieres apostar?${purpleColour} -> " && read initial_bet
  printf %b "${yellowColour}[+]${endColour} Quieres jugar con \"par\" o \"impar\"? ${purpleColour}-> " && read odd_even
  printf %b "\n${yellowColour}[+] ${endColour}Vamos a jugar con una cantidad inicial de: ${greenColour}\$$money${endColour} y a ${purpleColour}$odd_even${endColour}\n\n"
  tput civis
  let mg_streak=0;
  while true; do
    if [ "$top_money" -le "$money" ]; then
       top_money=$money
    fi

    let reward=0;
    let current_bet=$(($initial_bet+$mg_streak))

    if [ "$money" -le "$current_bet" ]; then
      current_bet="$money"
    fi

    money=$(($money-$current_bet))

#    printf %b "${yellowColour}[+] ${endColour}Acabas de apostar ${purpleColour}\$$current_bet${endColour}, a ${purpleColour}$odd_even${endColour}, saldo restante despues de la apuesta: ${greenColour}\$$money${endColour}\n"
    random_number="$(($RANDOM % 37))"
#    printf %b "${yellowColour}[!]${endColour} Salio el numero ${yellowColour}$random_number${endColour}\n"

    if [ "$(($random_number % 2))" -eq 0 ]; then
      if [ $random_number == 0 ]; then
	# 0
#	printf %b "${yellowColour}[-]${redColour} Perdiste \$$current_bet!${endColour}\n"
	mg_streak=$(($mg_streak+$current_bet))
	loss_streak+="$random_number "
      else
	# Numero par
	if [ "$odd_even" == "par" ]; then
	  reward=$(($current_bet*2))
	  mg_streak=0
	  loss_streak=""
#	  printf %b "${yellowColour}[+] ${greenColour}Ganaste!${endColour} Tu recompensa es: ${greenColour}\$$reward${endColour}\n"
  	else
#	  printf %b "${yellowColour}[-]${redColour} Perdiste \$$current_bet!${endColour}\n"
	  mg_streak=$(($mg_streak+$current_bet))
	  loss_streak+="$random_number "
	fi
      fi
    else
      # Numero impar
      if [ "$odd_even" == "impar" ]; then
        reward=$(($current_bet*2))
        mg_streak=0
	loss_streak=""
#	printf %b "${yellowColour}[+] ${greenColour}Ganaste!${endColour} Tu recompensa es: ${greenColour}\$$reward${endColour}\n"
      else
#	printf %b "${yellowColour}[-]${redColour} Perdiste \$$current_bet!${endColour}\n"
	mg_streak=$(($mg_streak+$current_bet))
	loss_streak+="$random_number "
      fi
    fi
    money=$(($money+$reward))
#    printf %b "${yellowColour}[+]${endColour} Tu nuevo saldo es de: ${yellowColour}\$$money${endColour}\n\n"
    if [ "$money" -le 0 ]; then
      printf %b "${redColour}[!] Perdiste todo tu dinero${endColour}\n\n"
      printf %b "${yellowColour}[+]${endColour} Jugaste un total de: ${yellowColour}$play_counter${endColour} veces\n\n"
      printf %b "${yellowColour}[+]${endColour} Las jugadas malas consecutivas fueron: ${redColour}[ $loss_streak]${endColour}\n"
      printf %b "${yellowColour}[+]${endColour} La mayor cantidad de dinero conseguida fue: ${greenColour}\$$top_money${endColour}\n\n"
      tput cnorm; exit 0
    fi
    let play_counter+=1
  done
  tpu cnorm
}

function inverseLabrouchere(){

  printf %b "\n${yellowColour}[+]${endColour} Dinero actual: ${greenColour}\$$money${endColour}\n"
#  printf %b "${yellowColour}[+]${endColour} Cuanto dinero quieres apostar?${purpleColour} -> " && read initial_bet
  printf %b "${yellowColour}[+]${endColour} Quieres jugar con \"par\" o \"impar\"? ${purpleColour}-> " && read odd_even
 
  declare -a sequence=(1 2 3 4)
   
  my_sequence=(${sequence[@]})
  
  #echo ${my_sequence[0]}
  #echo $lastmy_sequence
  
  play_count=0

  win_limit_reached=0
  loss_limit_reached=0
  loss_resets=0
  
  top_money=$money

  tput civis
  limit=$(($money+50)) 
  while true; do
    if [ "$money" -ge "$top_money" ]; then
      top_money=$money
    fi
    let play_count+=1

    if [ "${#my_sequence[@]}" -eq 0 ]; then
      my_sequence=(${sequence[@]})
      let loss_resets+=1
      printf %b "${redColour}[!] Secuencia terminada, reiniciando secuencia${endColour}\n\n"
    fi

    lastmy_sequence=$((${#my_sequence[@]}-1))
    
    if [ "${#my_sequence[@]}" -ne 1 ]; then
      bet=$((${my_sequence[0]} + ${my_sequence[lastmy_sequence]}))
      if [ "$money" -le "$bet" ]; then
        let bet=$money
      fi
    elif [ "${#my_sequence[@]}" -eq 1 ]; then
      bet=${my_sequence[0]}
      if [ "$money" -le "$bet" ]; then
        let bet=$money
      fi
    fi
    
    reward=$(($bet * 2))
    
    if [ "$money" -ge "$limit" ]; then
      let limit+=50
      my_sequence=(${sequence[@]})
      lastmy_sequence=$((${#my_sequence[@]}-1))
      bet=$((${my_sequence[0]} + ${my_sequence[lastmy_sequence]}))
      reward=$(($bet * 2))
      let win_limit_reached+=1
      printf %b "${greenColour}[!] Meta de \$50 alcanzada, reiniciando secuencia y limite a $limit${endColour}\n\n"
    elif [ "$money" -le "$(($limit - 100))" ]; then
      let limit-=50
      my_sequence=(${sequence[@]})
      lastmy_sequence=$((${#my_sequence[@]}-1))
      bet=$((${my_sequence[0]} + ${my_sequence[lastmy_sequence]}))
      reward=$(($bet * 2))
      let loss_limit_reached+=1
      printf %b "${redColour}[!] Perdiste tu meta de \$50, reiniciando secuencia y limite a $limit${endColour}\n\n"
    fi

    money=$(($money-$bet))

    printf %b "${yellowColour}[+]${endColour} Nuestra secuencia se queda en: ${turquoiseColour}[ ${my_sequence[@]} ]${endColour}, invertimos ${turquoiseColour}\$$bet${endColour}\n"  

    random_number=$(($RANDOM % 37))
    if [ "$(($random_number % 2))" -eq 0 ]; then
      if [ "$random_number" == 0 ]; then 
	unset my_sequence[0]
        unset my_sequence[$lastmy_sequence]
        printf %b "${redColour}[-] Perdiste! ${endColour}El numero fue cero: ${redColour}$random_number${endColour}, tu saldo se queda en: ${redColour}\$$money${endColour}\n\n"
      else
        if [ "$odd_even" == "par" ]; then
	  money=$(($reward + $money))
	  my_sequence+=($bet)
	  printf %b "${greenColour}[+] Ganaste! ${endColour}el numero fue par:${greenColour} $random_number${endColour}, tu nuevo saldo es: ${greenColour}\$$money${endColour}\n\n"
        else
	  unset my_sequence[0]
          unset my_sequence[$lastmy_sequence]
          printf %b "${redColour}[-] Perdiste! ${endColour}El numero fue par: ${redColour}$random_number${endColour}, tu saldo se queda en: ${redColour}\$$money${endColour}\n\n"
	fi
      fi
     else
      if [ "$odd_even" == "impar" ]; then
        money=$(($reward + $money))
	my_sequence+=($bet)
	printf %b "${greenColour}[+] Ganaste! ${endColour}el numero fue impar:${greenColour} $random_number${endColour}, tu nuevo saldo es: ${greenColour}\$$money${endColour}\n\n"
      else
        unset my_sequence[0]
        unset my_sequence[$lastmy_sequence]
        printf %b "${redColour}[-] Perdiste! ${endColour}El numero fue impar: ${redColour}$random_number${endColour}, tu saldo se queda en: ${redColour}\$$money${endColour}\n\n"
      fi
    fi
   # sleep 0.1
    my_sequence=(${my_sequence[@]})
    if [ "$money" -le 0 ]; then
      printf %b "${redColour}[!] Perdiste todo tu dinero${endColour}\n\n"
      printf %b "${yellowColour}[+]${endColour} Jugaste un total de: ${yellowColour}$play_count${endColour} veces\n\n"
      
      printf %b "${yellowColour}[+]${endColour} Los reinicios de secuencia fueron: ${redColour}[ $loss_resets ]${endColour}\n"
      
      printf %b "${yellowColour}[+]${endColour} La cantidad de reinicios de limite exitosos fueron: ${greenColour}$win_limit_reached${endColour}\n\n"

      printf %b "${yellowColour}[+]${endColour} La cantidad de reinicios de limite negativos fueron: ${redColour}$loss_limit_reached${endColour}\n\n"
      
      printf %b "${yellowColour}[+]${endColour} La mayor cantidad de dinero fue: ${greenColour}\$$top_money${endColour}\n\n"
      tput cnorm; exit 0
    fi
  done
  tput cnorm
}

# Ctrl + C
trap ctrl_c INT

while getopts "m:t:h" arg; do
  case $arg in
    m) money=$OPTARG;;
    t) technique=$OPTARG;;
    h) helpPanel;;
  esac
done

if [[ "$money" && "$technique" ]]; then
  echo -e "$money y con $technique"
  if [ "$technique" == "mg" ]; then
    martinGala
  elif [ "$technique" == "iv" ]; then
    inverseLabrouchere
  else
    printf %b "\n${redColour}[!] Tecnica no reconocida...${endColour}\n"
    helpPanel
  fi    
else
  helpPanel
fi
