#!/bin/bash
pause(){
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

print_status() {
    echo "## $1"
}


#<UDF name="key" Label="masternode genkey" default=""/>


clear
print_status "Before starting script ensure you have: "
print_status "100,000SYS sent to MN address, ran 'masternode genkey', and 'masternode outputs'"
print_status "Add the following info to the masternode config file (tools>open masternode config file) "
print_status "addressAlias vpsIp:8369 masternodePrivateKey transactionId outputIndex"
print_status "EXAMPLE------>mn1 65.65.65.65:8369 ctk9ekf0m3049fm930jf034jgwjfk zkjfklgjlkj3rigj3io4jgklsjgklsjgklsdj 0"
print_status "Restart SyscoinQT then return here"


#read -e -p "Server IP Address : " ip
UFW="Y"
install_fail2ban="Y"
ip=$(hostname -I | awk {'print $1'})
read -e -p "Masternode Private Key (From windows QT)) : " key
read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
read -e -p "Install UFW and configure ports? [Y/n] : " UFW
echo "IP set to $ip"
pause

# Create swapfile if less then 4GB memory
totalmem=$(free -m | awk '/^Mem:/{print $2}')
totalswp=$(free -m | awk '/^Swap:/{print $2}')
totalm=$(($totalmem + $totalswp))
if [ $totalm -lt 4000 ]; then
  print_status "Server memory is less then 4GB..."
  if ! grep -q '/swapfile' /etc/fstab ; then
    print_status "Creating a 4GB swapfile..."
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee --append /etc/fstab > /dev/null
    sudo mount -a
    print_status "Swap created"
  fi
fi


#Generating Random Passwords
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)


clear

print_status "Updating system"
sleep 5

# update package and upgrade Ubuntu
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
sudo apt-get install git -y

clear
print_status "Installing dependencies"
sleep 5

git clone https://github.com/syscoin/syscoin.git
cd syscoin
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libminiupnpc-dev -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

clear
print_status "Building syscoin core.. this will take a while"
sleep 5
./autogen.sh
clear
print_status "Still building..."
sleep 5
./configure
clear
print_status "Final build stage... go play outside for a while"
sleep 5
# speed up builds if you have more cores
BUILD_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
print_status "Compiling from source with $BUILD_CORES core(s)"
make -j$BUILD_CORES
clear
print_status "Installing syscoin and syscoin-cli binaries."
sudo make install
clear

mkdir $HOME/.syscoincore
cat <<EOF > $HOME/.syscoincore/syscoin.conf
#
rpcuser=user
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
#
listen=1
server=1
daemon=1
maxconnections=24
#
masternode=1
masternodeprivkey=$key
externalip=$ip
port=8369
EOF

clear
print_status "Starting syscoind"
sleep 5

syscoind

clear

clear
print_status "Installing node watchdog"
sleep 5

sudo apt-get install -y git python-virtualenv
sudo apt-get install -y virtualenv
git clone https://github.com/syscoin/sentinel.git $HOME/syscoin/src/sentinel
cd $HOME/syscoin/src/sentinel
cat <<EOF > $HOME/syscoin/src/sentinel/sentinel.conf
#syscoin conf location
syscoin_conf=$HOME/.syscoincore/syscoin.conf

#network
network=mainnet
#network=testnet

#db connection details
db_name=database/sentinel.db
db_driver=sqlite
EOF

virtualenv venv
sleep 5
venv/bin/pip install -r requirements.txt
sleep 5

#add cron for sentinel and syscoind
clear
print_status "Installing cron for watchdog and syscoind, setting up FW and fail2ban"
sleep 5

(crontab -l; echo "*/10 * * * * cd $HOME/syscoin/src/sentinel && ./venv/bin/python $HOME/syscoin/src/sentinel/bin/sentinel.py 2>&1 >> $HOME/sentinel-cron.log" ) | crontab -
(crontab -l; echo "@reboot $HOME/syscoin/src/syscoind -daemon") | crontab -
crontab -l

if [ $install_fail2ban == "y" ] || [ $install_fail2ban == "Y" ]
then
    print_status "installing f2b"
    sudo apt-get install fail2ban -y
    sudo service fail2ban restart
fi

if [ $UFW == "y" ] || [ $UFW == "Y" ]
then
    print_status "installing UFW"
    sudo apt-get install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 8369/tcp
    yes | sudo ufw enable
fi


clear

syscoin-cli mnsync status
syscoin-cli masternode status

print_status "If you see MASTERNODE_SYNC_FINISHED, return to QT and start your node."
print_status "If not, run syscoin-cli mnsync status to recheck"
print_status "Hope this helped yall set a node up! Donation addy SkSsc5DDejrXq2HfRf9B9QDqHrNiuUvA9Y"
