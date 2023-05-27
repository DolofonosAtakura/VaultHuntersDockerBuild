#!/bin/bash

# vh mod url: https://legacy.curseforge.com/minecraft/modpacks/vault-hunters-1-18-2/files/
# current forge v: 40.2.1
# i use java 17 right now

# variable set
echo "Capitalization matters throughout the script, I will NOT check for your messed up caps lock key."
sleep 3
echo "Java Max Ram (format example: 12G for 12 gigabytes)"
read javaMaxRam
echo "Java Min Ram (format example: 8G for 8 gigabytes)"
read javaMinRam
echo "Difficulty? (easy/medium/hard)"
read difficulty
echo "Seed? (just press enter if no seed to input)"
read seed
echo "Max players? (integer)"
read maxPlayers
echo "Port Number?"
read portNum
echo "Whitlist (true/false)"
read whitelist
echo "Do you wish to build a docker container with this? (yes/no)"
read dockeryn

# static vars that may change in the future
vhurl="https://mediafilez.forgecdn.net/files/4516/817/Vault+Hunters+3rd+Edition-Update-9.0.3_Server-Files.zip"
forgeurl="https://maven.minecraftforge.net/net/minecraftforge/forge/1.18.2-40.2.1/forge-1.18.2-40.2.1-installer.jar"
connMod="https://mediafilez.forgecdn.net/files/3833/738/connectivity-1.18.2-3.2.jar"

# SCRIPT START
echo "Please make sure you are in your working directory, I will NOT check for you."
echo "Type 'I accept' confirm that you are in your CWD."
read accept
if [ $accept != "I accept" ]; then
    echo "You cannot read, this script is not for you."
    sleep 10
    exit 1
fi

# check if we should run
# check java version (17+)
jVersion=$(java --version | grep '17\|18\|19\|20')
jvLen=${#jVersion[@]}
if [ $jVersion = "" ]; then
    echo "No matching java versions: try version 17 if you are having trouble. Stopping process."
    sleep 10
    exit 1
fi

# Make our working folder
mkdir VaultHunters
cd VaultHunters

# init pulls & variable setting
wget $vhurl
wget $forgeurl
zipfile=($(ls | grep ".zip"))
zipLen=$(echo "${#zipfile[@]}")
if [ $zipLen != "1" ]; then
    echo "REQUIRES 1 .zip file. Stopping process."
    sleep 10
    exit 1
fi
jarfile=($(ls | grep ".jar"))
jarLen=$(echo "${#jarfile[@]}")
if [ $jarLen != "1" ]; then
    echo "REQUIRES 1 .jar file. Stopping process."
    sleep 10
    exit 1
fi

javaSizes="-Xmx$javaMaxRam -Xms$javaMinRam"

serverProps="allow-flight=false allow-nether=true broadcast-console-to-ops=true broadcast-rcon-to-ops=true difficulty=$difficulty enable-command-block=true enable-jmx-monitoring=false enable-query=false enable-rcon=false enable-status=true enforce-whitelist=false entity-broadcast-range-percentage=100 force-gamemode=false function-permission-level=2 gamemode=survival generate-structures=true generator-settings={} hardcore=false hide-online-players=false level-name=world level-seed=$seed level-type=default max-players=$maxPlayers max-tick-time=60000 max-world-size=29999984 motd=VAULT_HUNTERS network-compression-threshold=256 online-mode=true op-permission-level=4 player-idle-timeout=0 prevent-proxy-connections=false pvp=true query.port=$portNum rate-limit=0 rcon.password= rcon.port=25575 require-resource-pack=false resource-pack= resource-pack-prompt= resource-pack-sha1= server-ip= server-port=$portNum simulation-distance=10 spawn-animals=true spawn-monsters=true spawn-npcs=true spawn-protection=16 sync-chunk-writes=true text-filtering-config= use-native-transport=true view-distance=16 white-list=$whitelist"

# unzip server files and forge jar, add connectivity mod | also add create any required file changes for server
unzip $zipfile
cd mods
wget $connMod
cd ..
java -jar $jarfile --installServer
echo "eula=true" > eula.txt
echo "
nogui" >> libraries/net/minecraftforge/forge/1.18.2-40.2.1/unix_args.txt
rm user_jvm_args.txt
touch user_jvm_args.txt
for i in $javaSizes; do echo $i >> user_jvm_args.txt; done
touch server.properties
for i in $serverProps; do echo $i >> server.properties; done

# stop for user to input server variables in
echo "Please input your user whitelist/blacklist/ops json files, then press enter"
read tempVar
echo "Please make any changes to server.properties now (these are set to use my preferred defaults), then press enter"
read tempVar
echo "If you are inputting a custom world, create a folder called 'world' and dump your files there. Then press enter."
read tempVar

# build docker container
if [ $dockeryn != "yes" ]; then
    echo "You have chosen not to setup docker (or you capitalized a letter, fix your reading skills). Process complete."
    sleep 10
    exit 1
fi
echo "This part is to build the docker container."
echo "I'm using sudo in these due to not having rootless setup. If you wish to continue, type 'CONTINUE'..."
read cont
if [ $cont != "CONTINUE" ]; then
    echo "You have chosen to stop. Process completed."
    sleep 10
    exit 1
fi

cd ..
sudo docker pull archlinux/archlinux:latest
IFS=$'\n'
dockerfile="FROM archlinux/archlinux:latest

WORKDIR /opt/VaultHunters

COPY ./VaultHunters /opt/VaultHunters

RUN pacman -Syu jdk17-openjdk --noconfirm && chown -R root /opt/VaultHunters

ENV PORT=$portNum

EXPOSE $portNum

CMD [\"/bin/bash\",\"./run.sh\"]"
touch dockerfile
for i in $dockerfile; do echo $i >> dockerfile; done


sudo docker build -t vaulthunters:3.9.0.3 .

echo "To start your container run (or build a docker-compose file for):"
echo "sudo docker run -p $portNum:$portNum vaulthunters:3.9.0.3"
