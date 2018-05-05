# Sys node setup install script
Fully automated EZ Install script for sys nodes

-Adds 4G swap if not present  
-Sets ip automatically  
-Updates VPS  
-Downloads all dependencies / builds syscoin  
-Installs sentinel, creates cronjob  
-Installs optional fail2ban  
-Sets firewall rules  
-Randomizes rpc password  

# To run clean install:
wget https://raw.githubusercontent.com/demesm/sysnodesetup/master/syssetup.sh  
sudo chmod 755 syssetup.sh  
sudo ./syssetup.sh

# To update to most recent:
sudo ./syssetup.sh -update


# Please READ all of the words at the beginning of the script. Make sure you do what it says and have information ready beforehand.

If you have sent your 100,000SYS to the MN address already you can run this and proceed to finish what needs to be done in QT. Once the script is done running, you can start your MN and be done with it, EZ!

You need your masternode priv key (generated from "masternode genkey" in QT.

There are some steps you will have to manually do such as editing the config file for QT to include your MN.
Everything on the VPS is automated after the 1st prompts.

If this helped you consider tossing some sys my way!  
SkSsc5DDejrXq2HfRf9B9QDqHrNiuUvA9Y
 
