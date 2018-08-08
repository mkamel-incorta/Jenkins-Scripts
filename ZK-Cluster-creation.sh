#echo "please enter the number of Zookeeper instances you need starting from 1: "
num=$1

CENTOS=` cat /etc/system-release 2>/dev/null | tr -d ' ' | awk -F "release" '{print $2}' | awk -F "." '{print $1}'`
UBUNTU=`lsb_release -a 2>/dev/null | grep "Distributor ID" | tr -d ' ' | awk -F ":" '{print $2}'`

if [ ! -z "$CENTOS" ]
then
        echo "OS is a CentOS with version: $CENTOS"
        
        if [ "$CENTOS" -lt 7 ]
        then
                echo "This Job can't be run on that machine as it needs CentOS 7 or higher"
                exit
        fi
        
        echo "Job is running now"

fi

if [ ! -z "$UBUNTU" ]
then
        echo "OS is $UBUNTU"
        echo "Job is running now"
fi

if [ -z "$CENTOS" ]  && [ -z "$UBUNTU" ]
then
        echo "OS is not Linux so Job can't be started"
        exit
fi

case $num in
        ''|*[!0-9]*) echo "Invalid Input"; echo "Please run the job again and provide correct input";exit;;
        *) echo "creating $num Zookeeper instances";;
esac

dockerLocation=`which docker`
if [ -z $dockerLocation ]
then
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install docker-ce
        sudo systemctl start docker

fi
dockerLocation=`which docker`
echo "docker package is installed in: $dockerLocation"

composeLocation=`which docker-compose`
if [ -z $composeLocation ]
then
        sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
fi
composeLocation=`which docker-compose`
echo "docker-compose package is installed in: $composeLocation"


echo "Start creating compose file"

touch ./zk.yml
#chmod 666 ./zk.yml

echo "version: '3.1'

services:" > zk.yml

server=""

for (( index=1; index<=$num; index++))
do
        server="$server server.$index=zoo${index}:2888:3888"
done

#echo "server: $server"

port=2181

for (( index=1; index<=$num; index++ ))
do
        echo " zoo${index}:" >> zk.yml
        echo "  image: zookeeper" >> zk.yml
        echo "  hostname: zoo${index}" >> zk.yml
        echo "  ports:" >> zk.yml
        echo "   - $port:2181" >> zk.yml
        echo "  environment:" >> zk.yml
        echo "   ZOO_MY_ID: $index" >> zk.yml
        echo "   ZOO_SERVERS:$server" >> zk.yml
        echo "" >> zk.yml
        port=`expr $port + 1`


done
echo "compose file has been created successfully"
cat zk.yml

sudo docker-compose -f zk.yml up -d

exit