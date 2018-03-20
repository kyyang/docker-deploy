show_status(){
	echo ""
        echo "############ stack status ###############" 
        docker stack ls |grep '^uApp' > .stack_status
	printf "%-30s %-10s\n" NAME SERVICE
	while read line;do
		printf "%-30s %-10s\n" $line
	done <  .stack_status

        echo "#########################################"
	echo ""

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
	
}

show_status
