#!/bin/bash
#afreslon
#requires the "at" package that allows to execute a given command later in time (as a planned job)
. ./env
create(){
	TODAY=$( date +%s )
	EXPIRATION_DATE=$( expr ${TODAY} + 1209600 )
	EXPIRATION_DATE=$( date -d@${EXPIRATION_DATE} )
	jobid=$( echo "./compute/stop_vapp.sh \x22cPod-${2}\x22">temp_stop_vapp.sh && chmod +x temp_stop_vapp.sh | at now+2weeks <temp_stop_vapp.sh 2>&1 | tail -n 1 | cut -d' ' -f 2 )
	echo ${jobid} >> lease.txt
	sed -i "$ s/$/ cpod-${2} ${3} stop" "lease.txt"
	jobid=$( echo "./delete_cpod.sh ${2} ${3}">temp_delete_cpod.sh && chmod +x temp_delete_cpod.sh | at now+3weeks <temp_delete_cpod.sh 2>&1 | tail -n 1 | cut -d' ' -f 2 )
	echo ${jobid} >> lease.txt
	sed -i "$ s/$/ cpod-${2} ${3} delete" "lease.txt"
	#./extra/post_slack.sh "Your cPod *${2}* will be available until *${EXPIRATION_DATE}*. On this date it'll be deleted"
}

delete(){
	jobid=$( grep "cpod-${2} stop" "lease.txt" | cut -d' ' -f 1 )
	atrm ${jobid}
	sed -i "/cpod-${2} ${3} stop/d" "lease.txt"
	jobid=$( grep "cpod-${2} ${3} delete" "lease.txt"| cut -d' ' -f 1 )
	atrm ${jobid}
	sed -i "/cpod-${2} ${3} delete/d" "lease.txt"
}

renew(){
	delete ${2} ${3}
	create ${2} ${3}
}
main(){
	if [ "${1}" == "" ] || [ "${2}" == "" ] || [ "${3}" == "" ]
	then 
		echo 'bad usage : ./cpod_lease.sh <action> (i.e create renew or delete) <cpod name> <owner>'
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
	esac
}

main $1 $2 $3
