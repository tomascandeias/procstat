#!/bin/bash
export LC_NUMERIC="en_US.UTF-8"
cd /proc
num_regex='^[0-9]+$'
sleep_period=${@: -1}
n=0


#Mensagem de erro
function error_prompt() {
	echo "Usage: $0 [-c <reg exp>] [-p <number of processes>] [-u <user>] [-m -t -d -w -r] " 1>&2	# redireciona stdout to stderr
	exit 1
}

#Verificar se o user_aux escreveu o periodo (ultimo argumento)
if ! [[ $sleep_period =~ $num_regex ]]; then
	error_prompt
fi



#Declaração de arrays
declare -a pids
declare -a comms
declare -a user
declare -a mem
declare -a rss
declare -a date
declare -a rchar
declare -a wchar
declare -a rater
declare -a ratew

#Variaveis auxiliares
regex=".*"
user_aux=0
num_of_procs=-1
count=1
flag_mem=0
flag_rss=0
flag_rateR=0
flag_rateW=0
flag_reverse='-r'
flag_reverse2=


#Definição dos argumentos e os respetivos erros
while getopts "c:p:u:mtdwr" flag; do
	case "$flag" in
		#-c restringe nome do comando
		c)
			regex=^${OPTARG}
			if [[ $regex =~ num_regex ]]; then
				error_prompt
			fi
			count=$((count + 2))
		;;
		#-p numero de processos
		p)
			num_of_procs=${OPTARG}
			
			if [[ $num_of_procs -le -1 ]]; then
				error_prompt
			fi
			count=$((count + 2))
		;;
		#-u definir user(s)
		u)
			user_aux=${OPTARG}
			count=$((count + 2))
		;;
		#-r reverter a tabela 
		r)
			flag_reverse=
			flag_reverse2='-r'
			count=$((count + 1))
		;;
		#-m ordernar por memoria
		m)			
			flag_mem=1
			count=$((count + 1))
		;;
		#-t ordernar por RSS
		t)
			flag_rss=1
			count=$((count + 1))
		;;
		#-d ordernar por Rate Read
		d)			
			flag_rateR=1
			count=$((count + 1))
		;;
		#-w ordernar por Rate Write
		w)
			flag_rateW=1
			count=$((count + 1))
		;;
		#Opções inválidas:
		\?)			
			error_prompt
		;;
		:)			
			error_prompt
		;;
	esac
done

if [[ $count -ne $# ]]; then
	error_prompt
fi



for pid in *; do
	if [[ $pid =~ $num_regex ]]; then

		#Extrair info para arrays
		pids[$n]=$pid
		comms[$pid]=$(cat /proc/$pid/comm)
		user[$pid]=$(ls -ld /proc/$pid | awk '{print $3}')
		mem[$pid]=$(cat /proc/$pid/status | grep "VmSize" | awk '{print $2}')
		rss[$pid]=$(cat /proc/$pid/status | grep "VmRSS" | awk '{print $2}')
		io=$( cat /proc/$pid/io 2>/dev/null )

		#Adicionar info aos arrays rchar wchar
		if [[ $? -ne 0 ]];then
			rchar[$pid]=-1
			wchar[$pid]=-1
		else
			rchar[$pid]=$(echo $io | grep "rchar" | awk '{print $2}')
			wchar[$pid]=$(echo $io | grep "wchar" | awk '{print $2}')
		fi

		#Adicionar date do processo
		date[$pid]=$(ls -ld /proc/$pid | awk '{print $6,$7,$8}')
		
		n=$((n + 1))

	fi
done


sleep $sleep_period
display_table=''

for pid in *; do
	if [[ $pid =~ $num_regex ]]; then
		if ! [[ $comms =~ (^|[[:space:]])$pid($|[[:space:]]) ]]; then
			
			if [[ "${user[$pid]}" == $user_aux || $user_aux == 0 ]] && [[ "${comms[$pid]}" =~ $regex ]]; then
				io=$( cat /proc/$pid/io 2>/dev/null )
				if [[ $? -ne 0 ]]; then
					rater[$pid]=-1
					ratew[$pid]=-1
				else
					#Calcular os rates
					oldRater=$(( $( echo $io | grep "rchar" | awk '{print $2}')-${rchar[$pid]} ))
					oldRatew=$(( $( echo $io  | grep "wchar" | awk '{print $2}')-${wchar[$pid]} ))
					rater[$pid]=$( echo "scale=2;$oldRater/$sleep_period" | bc )
					ratew[$pid]=$( echo "scale=2; $oldRatew/$sleep_period" | bc )
				fi
				
				if ! [[ "${rchar[$pid]}" == -1 ]]; then
					if ! [[ "${mem[$pid]}" == "" ]] || ! [[ "${rss[$pid]}" == "" ]] || ! [[ "${ratew[$pid]}" -eq $xyz ]]; then
						comms[$pid]=$( echo ${comms[$pid]} | cut -d " " -f1 )  #1ºcoluna
						printf -v linha "%-20s %-20s %6d %12d %12d %12d %12d %12.2f %12.2f %15s\n" "${comms[$pid]}" "${user[$pid]}" "$pid" "${mem[$pid]}" "${rss[$pid]}" "${rchar[$pid]}" "${wchar[$pid]}" "${rater[$pid]}" "${ratew[$pid]}" "${date[$pid]}"
						display_table="$display_table$linha" #adicionar o texto à variavel
					fi
				fi
			fi
		fi
	fi
done

#Impressão da tabela
printf "%-20s %-20s %6s %12s %12s %12s %12s %12s %12s %15s\n" "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"

if [[ $num_of_procs == -1 ]]; then
	if [[ $flag_mem == 1 ]]; then
		printf "%b" "$display_table" | sort -k 4 -g $flag_reverse
	elif [[ $flag_rss == 1 ]]; then
		printf "%b" "$display_table" | sort -k 5 -g $flag_reverse
	elif [[ $flag_rateR == 1 ]]; then
		printf "%b" "$display_table" | sort -k 8 -g $flag_reverse
	elif [[ $flag_rateW == 1 ]]; then
		printf "%b" "$display_table" | sort -k 9 -g $flag_reverse
	else
		printf "%b" "$display_table" | sort -k 1 -g $flag_reverse2
	fi
else
	if [[ $flag_mem == 1 ]]; then
		printf "%b" "$display_table" | sort -k 4 -g $flag_reverse | head -n $num_of_procs
	elif [[ $flag_rss == 1 ]]; then
		printf "%b" "$display_table" | sort -k 5 -g $flag_reverse | head -n $num_of_procs
	elif [[ $flag_rateR == 1 ]]; then
		printf "%b" "$display_table" | sort -k 8 -g $flag_reverse | head -n $num_of_procs
	elif [[ $flag_rateW == 1 ]]; then
		printf "%b" "$display_table" | sort -k 9 -g $flag_reverse | head -n $num_of_procs
	else
		printf "%b" "$display_table" | sort -k 1 -g $flag_reverse2 | head -n $num_of_procs
	fi
fi
