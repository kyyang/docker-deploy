config_file="./conf/publish-app-config.xml"

## get xml context
#$1 --> xml file, $2 --> node name, $3 --> nocdata
get_xml_value(){
	if [ X$3 == Xnocdata ];then
		echo `xmllint --xpath --nocdata "$2/text()" $1`
	else
		echo `xmllint --xpath "$2/text()" $1`
	fi
}

## get config
get_app_config(){
        appname=$1
local base_image_name=$(get_xml_value $config_file "//configuration/publicconfig/base_image_name")
local registry_url=$(get_xml_value $config_file "//configuration/publicconfig/registry_url")
local xml_app_name=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Name")
local app_port=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Port")
local app_xms=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Xms")
local app_xmx=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/Xmx")
local app_newsize=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/NewSize")
local networkname=$(get_xml_value $config_file "//configuration/services/service[Name[text()='$appname']]/NetworkName")
}

get_app_config ccb_xiaov
echo base_image_name: $base_image_name
echo  registry_url: $registry_url
echo xml_app_name: $xml_app_name
echo app_port: $app_port
echo app_xms: $app_xms
echo app_xmx: $app_xmx
echo app_newsize: $app_newsize
echo networkname: $networkname
exit


##test
echo base_image_name: $(get_xml_value ./conf/publish-app-config.xml "//configuration/publicconfig/base_image_name")
echo registry_url: $(get_xml_value ./conf/publish-app-config.xml "//configuration/publicconfig/registry_url")
echo app name: $(get_xml_value ./conf/publish-app-config.xml "//configuration/services/service[Name[text()='ccb_xiaov']]/Name")
echo app port: $(get_xml_value ./conf/publish-app-config.xml "//configuration/services/service[Name[text()='ccb_xiaov']]/Port")
echo Xms: $(get_xml_value ./conf/publish-app-config.xml "//configuration/services/service[Name[text()='ccb_xiaov']]/Xms")
echo Xmx: $(get_xml_value ./conf/publish-app-config.xml "//configuration/services/service[Name[text()='ccb_xiaov']]/Xmx")
echo NewSize: $(get_xml_value ./conf/publish-app-config.xml "//configuration/services/service[Name[text()='ccb_xiaov']]/NewSize")
echo Network Name: $(get_xml_value ./conf/publish-app-config.xml "//configuration/services/service[Name[text()='ccb_xiaov']]/NetworkName")
exit 0

