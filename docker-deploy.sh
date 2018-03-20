#/bin/bash
#Description: Automatically deploy container applications
#create by: yangkunyuan
#create data: 2018-03-16

worker_home="/data/script"
base_home="/data/appBase"
config_file="$worker_home/conf/publish-app-config.xml"
docker_compose_template_file="$worker_home/templates/docker-compose-template.yml"
docker_file_name="Dockerfile" #default value
tag_name=`date +%Y%m%d%H%M%S`
securePkg_flag=0


## get xml context
#$1 --> xml file, $2 --> node name, $3 --> nocdata
get_xml_value(){
	if [ X$3 == Xnocdata ];then
		echo `xmllint --xpath --nocdata "$2/text()" $1`
	else
		echo `xmllint --xpath "$2/text()" $1`
	fi
}

## get public config
registry_url=$(get_xml_value $config_file "//configuration/publicconfig/registry_url")
base_image_name=$(get_xml_value $config_file "//configuration/publicconfig/base_image_name")
base_image_url="${registry_url}/${base_image_name}"

## display help
display_help(){
	echo ""
	echo "Usage: `basename $0` start|stop|restart|build [app name] securePkg"
	echo "or"
	echo "Usage: `basename $0` status"
	exit 0
}

if [ $# -lt 2 ];then
	if [ $# -eq 1 ];then
		if [ $1 == "status" ];then
			echo ""
		fi
	else
		display_help
	fi

elif [ $# -eq 2 ];then
	appname=$2
	echo "appname: $appname"
	if [ ! -d $base_home/$appname ];then
		echo "$appname is not found"
		exit 0
	fi
elif [ $# -eq 3 ];then
	appname=$2
	if [ ! -d $base_home/$appname ];then
		echo "$appname is not found"
		exit 0
	fi
	if [ $3 == "securePkg" ];then
		securePkg_flag=1
		base_image_url="${base_image_url}_securePkg"
		docker_file_name="Dockerfile.securePkg"
	else
		display_help
	fi
elif [ X$1 == "Xstatus" ];then
	echo ""
else
	display_help
fi
app_image_url="${registry_url}/${appname}:${tag_name}"

## gen docker file
gen_docker_file(){
	cd $app_home
	echo "FROM $base_image_url" > $docker_file_name
	echo 'MAINTAINER wacld "kyvicp@gmail.com"' >> $docker_file_name
	echo "" >> $docker_file_name
	echo "ADD ./webapps /usr/local/tomcat-8.5.27/webapps" >> $docker_file_name
}

## docker build
docker_build_app_images(){
	cd $app_home
	docker build -t $app_image_url . -f $docker_file_name
	if [ $? -ne 0 ];then
		echo "$appname images build is failed."
		exit 0
	fi
}

## docker push
docker_push_registry(){
	docker tag $app_image_url  ${registry_url}/${appname}:letest
	docker push $app_image_url
	docker push ${registry_url}/${appname}:letest
}

## gen docker compose file
#$1 --> app name, $2 --> app_image_url
gen_docker_compose_file(){
	appname="$1"
	app_image_url="$2"

	app_port=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Port")
	xms_value=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Xms")
	xmx_value=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Xmx")
	newsize_value=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/NewSize")
	replicas_num=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/ReplicasNum")
	network_name=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/NetworkName")

	service_name="uApp_$appname"  #uApp_$appname
	applog_path="/applog/$appname" #/applog/$appname
	compose_file="docker-compose-${service_name}_cluster.yml"

	cd $app_home
	test -f $compose_file && rm -f $compose_file
	cp $docker_compose_template_file $compose_file

	if [ $securePkg_flag -eq 0 ];then
		sed -i "/\/conf\/context.xml/d" $compose_file
		sed -i "/\/var\/\/infrImgBase\/tomcat\/tomcat/d" $compose_file
	fi
	sed -i "s/{{SERVICE_NAME}}/$service_name/g" $compose_file
	sed -i "s#{{IMAGE_URL}}#$app_image_url#g" $compose_file
	sed -i "s/{{REPLICAS_NUMBER}}/$replicas_num/g" $compose_file
	sed -i "s/{{NEWSIZE}}/$newsize_value/g" $compose_file
	sed -i "s/{{APP_PORT}}/$app_port/g" $compose_file
	sed -i "s/{{NETWORK_NAME}}/$network_name/g" $compose_file
	sed -i "s/{{XMS}}/$xms_value/g" $compose_file
	sed -i "s/{{XMX}}/$xmx_value/g" $compose_file
	sed -i "s#{{APPLOG_PATH}}#$applog_path#g" $compose_file
}

## deploy application
docker_deploy_stack(){
	service_name=$1
	compose_file="docker-compose-${service_name}_cluster.yml"

	cd $app_home
	docker stack deploy -c $compose_file  $service_name --with-registry-auth
}

## uninstall application
docker_destroy_app(){
	service_name=$1
	n=`docker stack ls|grep -w "$service_name" |wc -l`
	if [ $n -ne 0 ];then
		docker stack rm $service_name
	fi
}

## docker build
docker_build(){
	gen_docker_file
	docker_build_app_images
	docker_push_registry:letest
}

## show status
show_status(){
        echo "############ stack status ###############"
        docker stack ls |grep '^uApp' > .stack_status
	printf "%-30s %-10s\n" NAME SERVICE
	while read line;do
		printf "%-30s %-10s\n" $line
	done <  .stack_status

        echo "#########################################"

	echo ""
        echo "################################### services status #########################################"
	docker service ls  --format "{{.Name}} {{.Mode}} {{.Replicas}} {{.Ports}}"|grep "^uApp_" > .status
	printf "%-50s %-11s %-11s %-20s\n" SERVICENAME MODE REPLICAS PORT
	#echo "---------------------------------------------------------------------------------------------"
	while read line;do
		printf "%-50s %-11s %-11s %-20s\n" $line
	done < .status
	echo ""

	#docker service ps uApp_ccb_xiaov_uApp_ccb_xiaov --format "{{.Name}} {{.Node}} {{.DesiredState}} {{.CurrentState}}"
        echo "################################# service status details #####################################"
	printf "%-50s %-30s %-15s %-15s\n" SERVICE NODE STATE
	services=`docker service ls --format "{{.Name}}" |grep '^uApp'`
	for service in $services;do
		printf "%-50s %-30s %-15s\n" `docker service ps $service --format "{{.Name}} {{.Node}} {{.DesiredState}}"`
	done
	echo ""
}

##################################################################
## main
#################################################################
app_home="$base_home/$appname"
service_name="uApp_$appname"
case $1 in
	"start")
		#docker_build
		docker_deploy_stack $service_name
		show_status
		;;
	"stop")
		docker_destroy_app $service_name
		;;
	"restart")
		docker_destroy_app $service_name
		docker_deploy_stack $service_name
		show_status
		;;
	"status")
		show_status
		;;
	"build")
		docker_build
		;;
	*) display_help;;
esac
