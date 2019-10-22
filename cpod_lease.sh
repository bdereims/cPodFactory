#!/bin/bash
#afreslon
#requires the "at" package that allows the execution of a given command later in time (as a planned job)
#please make sure the atd service is started and "enabled" (aka will restart if unexpectidly killed)

. ./env

[ "${LEASE}" == "NO" ] && exit 0

create(){
	TODAY=$( date +%s )
	EXPIRATION_DATE=$( expr ${TODAY} + 1209600 )
	EXPIRATION_DATE=$( date -d@${EXPIRATION_DATE} )

	jobid=$( echo "./compute/stop_vapp.sh ${1} && sleep 3s && rm extra/leases/temp_stop_vapp_cpod-${1}.sh">extra/leases/temp_stop_vapp_cpod-${1}.sh && chmod +x extra/leases/temp_stop_vapp_cpod-${1}.sh && at now+2weeks <extra/leases/temp_stop_vapp_cpod-${1}.sh 2>&1 | tail -n 1 | cut -d' ' -f 2 )
	echo ${jobid} >> extra/leases/leases.txt
	sed -i "$ s/$/ cpod-${1} ${2} stop/" "extra/leases/leases.txt"
	jobid=$( echo "./delete_cpod.sh ${1} ${2} && sleep 3s && rm extra/leases/temp_delete_cpod-${1}.sh">extra/leases/temp_delete_cpod-${1}.sh && chmod +x extra/leases/temp_delete_cpod-${1}.sh && at now+3weeks <extra/leases/temp_delete_cpod-${1}.sh 2>&1 | tail -n 1 | cut -d' ' -f 2 )
	echo ${jobid} >> extra/leases/leases.txt
	sed -i "$ s/$/ cpod-${1} ${2} delete/" "extra/leases/leases.txt"
	./extra/post_slack.sh ":warning: Your cPod *${1}* will be available until *${EXPIRATION_DATE}*. On this date it'll be deleted :warning:"
	#./extra/post_slack.sh "/remind @${2} Your cPod *${1}* will be deleted in 3 days if you don't reach to our team in 11 days"
}

delete(){
	jobid=$( grep "cpod-${1} ${2} stop" "extra/leases/leases.txt" | cut -d' ' -f 1 )
	atrm ${jobid} 2>/dev/null
	if [ $? -eq 0 ]
	then
		sed -i "/cpod-${1} ${2} stop/d" "extra/leases/leases.txt"
		rm "extra/leases/temp_stop_vapp_cpod-${1}.sh"
		jobid=$( grep "cpod-${1} ${2} delete" "extra/leases/leases.txt"| cut -d' ' -f 1 )
		atrm ${jobid}
		sed -i "/cpod-${1} ${2} delete/d" "extra/leases/leases.txt"
		rm "extra/leases/temp_delete_cpod-${1}.sh"
	else
		echo "cPod ${1} either doesn't exist or doesn't have a lease applied to it"
	fi
}

renew(){
	delete ${1} ${2}
	create ${1} ${2}
}
debug(){
	#truc=$( echo "./../../debug.sh ${1} ${2} && sleep 300 && rm temp_delete_cpod-${1}.sh"> extra/leases/temp_delete_cpod-${1}.sh && chmod +x extra/leases/temp_delete_cpod-${1}.sh | at now+1minutes <extra/leases/temp_delete_cpod-${1}.sh 2>&1 | tail -n 1 | cut -d' ' -f 2 )
	ls
	machin=$( echo "./../../debug.sh ${1} ${2} && sleep 3s && rm machin.sh" > extra/leases/machin.sh && chmod +x extra/leases/machin.sh && at now+1minutes <extra/leases/machin.sh 2>&1 | tail -n 1 | cut -d' ' -f 2 )
	echo ${machin}
	ls extra/leases
	atq
	cat extra/leases/extra/leases/leases.txt
}
main(){
	if [ "${1}" == "" ] || [ "${2}" == "" ] || [ "${3}" == "" ]
	then 
		echo 'bad usage : ./cpod_lease.sh <action> (i.e create, renew, delete or debug) <cpod name> <owner>'
		exit 1
	fi

	case $1 in
		create)
			create $2 $3
			;;
		renew)
			renew $2 $3
			;;
		delete)
			delete $2 $3
			;;
		debug)
			debug $2 $3
			;;
		*)
		echo "${1} isn't a valid action"
		;;
	esac
}

main $1 $2 $3
