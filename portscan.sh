#!/bin/bash

nmap_arguments=()
# Loop para capturar flags
while getopts ":g:" opt; do
		case "$opt" in
				g)	  nmap_arguments+="-$opt $OPTARG";;
				\?)	 echo "Opção inválida: -$OPTARG"; exit 1;;
				:)	  echo "Faltou argumento da opção -$OPTARG"; exit 1;;
		esac
done

# Remove da lista todos os argumentos que o getopts consumiu
shift $((OPTIND - 1))

if [ "$1" == "" ]
then
		printf "Modo de uso: $0 [-g <porta>] <host>\n"
		printf "Exemplo: $0 192.168.0.20\n"
else
	nmap_arguments+=" -Pn $1"
	printf "Escaneando top 100 portas TCP...\n\n"
	nmap --top-ports=100 --open $nmap_arguments -o tcp100.scanning
	mv tcp100.scanning tcp100.done
	grep -v '#' tcp100.done | grep -v -E 'filtered|closed' | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > tcp100-ports.done
	if [ -s tcp100-ports.done ]
	then
		printf "\nPortas TCP abertas: $(cat tcp100-ports.done)\n\n"
	else
		printf "Nenhuma porta TCP encontrada\n\n"
	fi

	printf "Escaneando top 1000 portas TCP...\n\n"
	nmap --top-ports=1000 --open $nmap_arguments -o tcp1000.scanning
	mv tcp1000.scanning tcp1000.done
	grep -v '#' tcp1000.done | grep -v -E 'filtered|closed' | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > tcp1000-ports.done
	if [ -s tcp1000-ports.done ]
	then
		printf "\nPortas TCP abertas: $(cat tcp1000-ports.done)\n\n"
	else
		printf "Nenhuma porta TCP encontrada\n\n"
	fi

	printf "Escaneando top 10 portas UDP...\n\n"
	nmap -sU --top-ports=10 --open $nmap_arguments -o udp10.scanning
	mv udp10.scanning udp10.done
	grep -v '#' udp10.done | grep -v -E 'filtered|closed' | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > udp10-ports.done
	if [ -s udp10-ports.done ]
	then
		printf "\nPortas UDP abertas: $(cat udp10-ports.done)\n\n"
	else
		printf "Nenhuma porta UDP encontrada\n\n"
	fi

	printf "Escaneando todas as portas TCP...\n\n"
	nmap -p- --open $nmap_arguments -o tcpAll.scanning
	mv tcpAll.scanning tcpAll.done
	grep -v '#' tcpAll.done | grep -v -E 'filtered|closed' | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > tcpAll-ports.done
	if [ -s tcpAll-ports.done ]
	then
		printf "Portas TCP abertas: $(cat tcpAll-ports.done)\n\n"
		printf "Escaneando serviços nas portas TCP encontradas...\n\n"
		nmap -sSV -p$(cat tcpAll-ports.done) $nmap_arguments > tcpServices.scanning
		mv tcpServices.scanning tcpServices.done
	else
		printf "Nenhuma porta TCP encontrada\n\n"
	fi

	printf "Escaneando top 100 portas UDP...\n\n"
	nmap -sU --top-ports=100 --open $nmap_arguments -o udp100.scanning
	mv udp100.scanning udp100.done
	grep -v '#' udp100.done | grep -v -E 'filtered|closed' | grep open | cut -d " " -f1 | cut -d "/" -f1 | tr '\n' ',' | sed 's/,$//' > udp100-ports.done
	if [ -s udp100-ports.done ]
	then
		printf "\nPortas UDP abertas: $(cat udp100-ports.done)\n\n"
		printf "Escaneando serviços nas portas UDP encontradas...\n\n"
		nmap -sUV -p$(cat udp100-ports.done) $nmap_arguments > udpServices.scanning
		mv udpServices.scanning udpServices.done
	else
		printf "Nenhuma porta UDP encontrada\n\n"
	fi

	printf "\nEscaneamento completo!\n"
	printf "Serviços TCP: \n" >> services
	sed -n '/PORT/,/Service Info/p' tcpServices.done >> services
	printf "\nServiços UDP: \n" >> services
	sed -n '/PORT/,/Service Info/p' udpServices.done >> services
	cat services
fi