#!/bin/bash
#NAME: naet.sh
#AUTHOR: Marcos Cano  2015
#CONTACT INFO: jmarcos.cano@gmail.com , marcos.cano@galileo.edu
#VERSION: 1.0 
#DESCRIPTION: 


#simulate the conf file
bmx6_containers=2
bmx_network=
bmx_netmask=
olsrd_containers=2
olsr_network=
olsr_netmask=


## deberian ser leidas del conf file
#GENERAL
waf_path=/home/emulation/repos/ns-3-allinone/ns-3-dev/
verbose=false
logfile="logs/naet.log"
persistence=true
container_log_path=log/


config_files_path="conf/"
template_files_dir="templates/"
container_expr="container"
network="10.0.0.0"
netmask="/8"


if $verbose;then 
	set -x
fi
# if [[ $USER != "root" ]]; then 
# 		echo "This script must be run as root!" 
# 		exit 1
# fi 


#tools()
#docker logs docker-$id



#######################
# usage()
# script usage
#######################
usage(){

	cat <<-EOU
	usage :   $0  [OPTIONS]  

	OPTIONS:
	    start|--start|-start|-s|--s    <config file>               starts NAET with a config file  :)


	    destroy|--destroy|-destroy|-d|--d  <all| containerID>      destroys a containerID or all

	    -print                                                     prints the current configuration

	    -help,-h,--help                                            prints this message
	

	NOTE: if no configuration file is provided  while start it will use the default one

	EOU
}



#######################
#attach()
#description:
# attach to a running container
#######################
attach(){
	id=$1
	docker attach docker-$id
}


#######################
# log()
# description:
# a bash utility to log msgs to $logfile
# $1 = message to log
#######################
log(){
	message=$1
	date=$(echo [ $(date +%D-%T) ])
	#echo "logging utility"
	if $logging;then
		echo $date $message | tee -a $logfile
	else
		echo $date $message
	fi
}


#######################
# destroy()
# description:
# function to destroy a single container
# or destroy all
#######################
destroy(){

	id=$1
	#destroy containers
	#lxc-destroy -n container-${id}
	###bridge down
	ifconfig "br-${id}" down
	###rm taps from bridges
	brctl delif br-${id} tap-${id}
	###destroy the bridges
	brctl delbr br-${id}
	###taps down
	ifconfig tap-${id} down
	###delete taps
	tunctl -d tap-${id}
	##delete iplink
	ip link del $id-A
	ip link del $id-B

	docker kill docker-$id
	docker rm docker-$id
}


#######################
# create()
# description:
# ID = $1 
# note: the number or name of the container and 
# all interfaces linked to it, 
# TYPE = $2
# should contain the type of the container
# i.e: olsrd ,  bmx6
# note: bmx6 or olrsd
#######################
count=1
create(){	
		#read -p ""
		type=$2
		if [ ! -z "$type" ];then	
			id=$type-$1
		else
			id=$1
		fi

		#id=$1
		### SET VARIABLES
		bridge="br-${id}"
		tap="tap-${id}"
		sideA="$id-A"
		sideB="$id-B"
		
		#make sure everything is destroyed before creating it.
		destroy $id &>/dev/null
		### CREATE OUTER BRIDGES
		brctl addbr $bridge \
		&& tunctl -t $tap \
		&& ifconfig $tap 0.0.0.0 promisc up \
		&& brctl addif $bridge $tap \
		&& ifconfig $bridge up 

		#echo "outer bridge $bridge created"
		log "BRIDGES: br: $bridge tap: $tap CREATED"

		#EL ID DEBERIA TENER TAMBIEN EL TIPO!!!
		#try
		{
		#docker run --privileged -i -t -d --net=none --name docker-$id docker-naet:latest -t $type -i $id && #2>/dev/null
		docker run -v $(pwd)/logs:/var/log  --entrypoint /bin/bash --privileged -i -t --rm --net=none --name docker-$id docker-naet:latest  -c "/bin/bash"
		#echo "DOCKER: docker-$id CREATED"
		log "DOCKER: docker-$id  ID: $id TYPE: $type CREATED"
		}|| # catch
		{
			echo "DOCKER issues creating docker-$id"
			#exit 0
		}
		

		pid=$(docker inspect -f '{{.State.Pid}}' docker-${id} )
		mkdir -p /var/run/netns 
		ln -s /proc/$pid/ns/net /var/run/netns/$pid

		ip link add $sideA type veth peer name $sideB
		brctl addif $bridge $sideA
		ip link set $sideB netns $pid
		ip netns exec $pid ip link set dev $sideB name eth0
		ip netns exec $pid ip link set eth0 up
		ip netns exec $pid ip addr add 10.0.0.$count/8 dev eth0   #network???
		ip link set $sideA up

		#log the name of the container and all interfaces attached to it

		## if everything went ok count++
		log "NETWORK inside DOCKER: docker-$id IP:$10.0.0.$count/8    CREATED and ATTACHED to BRIDGES"
		count=$((count +1 ))
		log ""

}


template(){
	echo "templating cpp"


}

config_reader(){
	echo "config reader"
}

start(){
	i=2
	for machine in {0..};do
		echo $machine

	done

}



if [ $# -gt 0 ] ;then
	
	args=$@
	case $1 in
		start|--start|-start|-s|--s)
			#echo "start"
			if [ ! -z $2 ];then
				conf_file=$2
				if [ -f $conf_file ];then
					#echo "conf: $conf_file found"
					#step 1:
					echo "lets read it"
					#step 2:
					start

				else
					echo "conf file: '$conf_file' NOT FOUND"
					exit 0
				fi	
			else
				echo [ERROR] config file not provided
				usage
			fi
		;;
		destroy|--destroy|-destroy|-d|--d)
			#echo destroy
			if [ ! -z $2 ];then
				echo "destroy"


			else
				echo "[ERROR] destroy all or a specific ID?"
				exit 0
			fi
		;;	
		help|--help|-h|--h|-help)
				usage
				;;
		print)
			echo " print the current config"
			;;
		*)
		usage
		;;
	esac
else
	usage
fi


