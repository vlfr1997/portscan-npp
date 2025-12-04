#!/bin/bash

nmap_arguments=()
verbose=false
REDIRECT=""
SPINNER_PID=0

# Função para limpar o spinner em caso de interrupção (Ctrl+C)
cleanup_spinner() {
    if [ "$SPINNER_PID" != "0" ]; then
        kill "$SPINNER_PID" 2> /dev/null
    fi
    printf "\n\nEscaneamento interrompido.\n"
	# Sai com código 130 (interrupção por Ctrl+C)
	exit 130
}

# Função que executa a animação de loading em background
start_spinner() {
    SPIN='|/-\'
    i=0
    
    # Roda em background
    while :
    do
        # Sobrescreve apenas o último caractere (spinner)
        printf "\b${SPIN:i%${#SPIN}:1}" 
        i=$((i + 1))
        sleep 0.1
    done &
    
    SPINNER_PID=$!
}

# Função que para a animação de loading e imprime 'OK'
stop_spinner() {
    if [ "$SPINNER_PID" != "0" ]; then
        # Silencia a mensagem 'Killed' do shell redirecionando o STDERR
        kill "$SPINNER_PID" 2> /dev/null
        
        # O '\b' volta um espaço (apagando o spinner) e o 'OK\n' finaliza a linha
        printf "\bOK\n" 
        SPINNER_PID=0
    fi
}

# Configura o trap para capturar Ctrl+C e chamar a função de limpeza
trap cleanup_spinner INT

# Loop para capturar flags
while getopts ":g:v" opt; do
		case "$opt" in
				g)	  nmap_arguments+="-$opt $OPTARG";;
				v)    verbose=true;;
				\?)	  echo "Opção inválida: -$OPTARG"; exit 1;;
				:)	  echo "Faltou argumento da opção -$OPTARG"; exit 1;;
		esac
done

# Remove da lista todos os argumentos que o getopts consumiu
shift $((OPTIND - 1))

if [ "$1" == "" ]
then
		printf "Modo de uso: $0 [-g <porta>] [-v] <host>\n"
		printf "Exemplo: $0 192.168.0.20\n"
		printf "Exemplo: $0 -g 23 -v 192.168.0.20\n"
else
	# Configura redirecionamento de saída se não for modo verbose
	if [ "$verbose" = false ]
	then
		REDIRECT="> /dev/null 2>&1"
	fi

	nmap_arguments+=" -Pn $1"
	printf "\rEscaneando top 100 portas TCP... "
	if [ "$verbose" = false ]
	then
		start_spinner
		eval nmap --top-ports=100 --open $nmap_arguments -o tcp100.scanning $REDIRECT
		stop_spinner
	else
		printf "\n\n"
		eval nmap --top-ports=100 --open $nmap_arguments -o tcp100.scanning $REDIRECT
	fi
	mv tcp100.scanning tcp100.done
	grep -v '#' tcp100.done | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > tcp100-ports.done

	if [ -s tcp100-ports.done ]
	then
		eval printf "\nPortas TCP abertas: $(cat tcp100-ports.done)\n\n" $REDIRECT
	else
		printf "\n\n"
		eval printf "Nenhuma porta TCP encontrada\n\n" $REDIRECT
	fi

	printf "\rEscaneando top 1000 portas TCP... "
	if [ "$verbose" = false ]
	then
		start_spinner
		eval nmap --top-ports=1000 --open $nmap_arguments -o tcp1000.scanning $REDIRECT
		stop_spinner
	else
		printf "\n\n"
		eval nmap --top-ports=1000 --open $nmap_arguments -o tcp1000.scanning $REDIRECT
	fi
	mv tcp1000.scanning tcp1000.done
	grep -v '#' tcp1000.done | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > tcp1000-ports.done
	if [ -s tcp1000-ports.done ]
	then
		eval printf "\nPortas TCP abertas: $(cat tcp1000-ports.done)\n\n" $REDIRECT
	else
		printf "\n\n"
		eval printf "Nenhuma porta TCP encontrada\n\n" $REDIRECT
	fi

	printf "\rEscaneando top 10 portas UDP... "
	if [ "$verbose" = false ]
	then
		start_spinner
		eval nmap -sU --top-ports=10 --open $nmap_arguments -o udp10.scanning $REDIRECT
		stop_spinner
	else
		printf "\n\n"
		eval nmap -sU --top-ports=10 --open $nmap_arguments -o udp10.scanning $REDIRECT
	fi
	mv udp10.scanning udp10.done
	grep -v '#' udp10.done |  grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > udp10-ports.done
	if [ -s udp10-ports.done ]
	then
		eval printf "\nPortas UDP abertas: $(cat udp10-ports.done)\n\n" $REDIRECT
	else
		eval printf "\n\nNenhuma porta UDP encontrada\n\n" $REDIRECT
	fi

	printf "\rEscaneando todas as portas TCP... "
	if [ "$verbose" = false ]
	then
		start_spinner
		eval nmap -p- --open $nmap_arguments -o tcpAll.scanning $REDIRECT
		stop_spinner
	else
		printf "\n\n"
		eval nmap -p- --open $nmap_arguments -o tcpAll.scanning $REDIRECT
	fi
	mv tcpAll.scanning tcpAll.done
	grep -v '#' tcpAll.done | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > tcpAll-ports.done
	if [ -s tcpAll-ports.done ]
	then
		eval printf "Portas TCP abertas: $(cat tcpAll-ports.done)\n\n" $REDIRECT
		printf "\rEscaneando serviços nas portas TCP encontradas... "
		if [ "$verbose" = false ]
		then
			start_spinner
			eval nmap -sSV -p$(cat tcpAll-ports.done) $nmap_arguments -o tcpServices.scanning $REDIRECT
			stop_spinner
		else
			printf "\n\n"
			eval nmap -sSV -p$(cat tcpAll-ports.done) $nmap_arguments -o tcpServices.scanning $REDIRECT
		fi
		mv tcpServices.scanning tcpServices.done
	else
		eval printf "\n\nNenhuma porta TCP encontrada\n\n" $REDIRECT
	fi

	printf "\rEscaneando top 100 portas UDP... "
	if [ "$verbose" = false ]
	then
		start_spinner
		eval nmap -sU --top-ports=100 --open $nmap_arguments -o udp100.scanning $REDIRECT
		stop_spinner
	else
		printf "\n\n"
		eval nmap -sU --top-ports=100 --open $nmap_arguments -o udp100.scanning $REDIRECT
	fi
	mv udp100.scanning udp100.done
	grep -v '#' udp100.done |  grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > udp100-ports.done
	if [ -s udp100-ports.done ]
	then
		eval printf "\nPortas UDP abertas: $(cat udp100-ports.done)\n\n" $REDIRECT
		printf "\rEscaneando serviços nas portas UDP encontradas... "
		if [ "$verbose" = false ]
		then
			start_spinner
			eval nmap -sUV -p$(cat udp100-ports.done) $nmap_arguments -o udpServices.scanning $REDIRECT
			stop_spinner
		else
			printf "\n\n"
			eval nmap -sUV -p$(cat udp100-ports.done) $nmap_arguments -o udpServices.scanning $REDIRECT
		fi
		mv udpServices.scanning udpServices.done
	else
		eval printf "Nenhuma porta UDP encontrada\n\n" $REDIRECT
	fi

	printf "Escaneamento completo!\n\n"
	printf "Serviços TCP: \n" >> services
	if [ -s tcpServices.done ]
	then
		sed -n '/PORT/,/Service/p' tcpServices.done | sed '/please submit/,/Service Info/{/Service Info:/!d}' | sed '/Service detection/d' | sed '/^$/d' >> services
	else
		printf "Nenhum serviço TCP encontrado.\n" >> services
	fi
	printf "\nServiços UDP: \n" >> services
	if [ -s udpServices.done ]
	then
		sed -n '/PORT/,/Service/p' udpServices.done | sed '/please submit/,/Service Info/{/Service Info:/!d}' | sed '/Service detection/d' | sed '/^$/d' >> services
	else
		printf "Nenhum serviço UDP encontrado.\n" >> services
	fi
	cat services
fi