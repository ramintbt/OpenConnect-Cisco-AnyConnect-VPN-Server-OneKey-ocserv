#!/usr/bin/env bash

if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

cd ~
echo '
 ▒█████   ██▓███  ▓█████  ███▄    █     ▄████▄   ▒█████   ███▄    █  ███▄    █ ▓█████  ▄████▄  ▄▄▄█████▓
▒██▒  ██▒▓██░  ██▒▓█   ▀  ██ ▀█   █    ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █  ██ ▀█   █ ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒
▒██░  ██▒▓██░ ██▓▒▒███   ▓██  ▀█ ██▒   ▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▓██  ▀█ ██▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░
▒██   ██░▒██▄█▓▒ ▒▒▓█  ▄ ▓██▒  ▐▌██▒   ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒▓██▒  ▐▌██▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ 
░ ████▓▒░▒██▒ ░  ░░▒████▒▒██░   ▓██░   ▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░▒██░   ▓██░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ 
░ ▒░▒░▒░ ▒▓▒░ ░  ░░░ ▒░ ░░ ▒░   ▒ ▒    ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   
  ░ ▒ ▒░ ░▒ ░      ░ ░  ░░ ░░   ░ ▒░     ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░░ ░░   ░ ▒░ ░ ░  ░  ░  ▒       ░    
░ ░ ░ ▒  ░░          ░      ░   ░ ░    ░        ░ ░ ░ ▒     ░   ░ ░    ░   ░ ░    ░   ░          ░      
    ░ ░              ░  ░         ░    ░ ░          ░ ░           ░          ░    ░  ░░ ░               
                                       ░                                              ░                 
 ██▒   █▓ ██▓███   ███▄    █      ██████ ▓█████  ██▀███   ██▒   █▓▓█████  ██▀███                        
▓██░   █▒▓██░  ██▒ ██ ▀█   █    ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓█   ▀ ▓██ ▒ ██▒                      
 ▓██  █▒░▓██░ ██▓▒▓██  ▀█ ██▒   ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒███   ▓██ ░▄█ ▒                      
  ▒██ █░░▒██▄█▓▒ ▒▓██▒  ▐▌██▒     ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░▒▓█  ▄ ▒██▀▀█▄                        
   ▒▀█░  ▒██▒ ░  ░▒██░   ▓██░   ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░▒████▒░██▓ ▒██▒                      
   ░ ▐░  ▒▓▒░ ░  ░░ ▒░   ▒ ▒    ▒ ▒▓▒ ▒ ░░░ ▒░ ░░ ▒▓ ░▒▓░   ░ ▐░  ░░ ▒░ ░░ ▒▓ ░▒▓░                      
   ░ ░░  ░▒ ░     ░ ░░   ░ ▒░   ░ ░▒  ░ ░ ░ ░  ░  ░▒ ░ ▒░   ░ ░░   ░ ░  ░  ░▒ ░ ▒░                      
     ░░  ░░          ░   ░ ░    ░  ░  ░     ░     ░░   ░      ░░     ░     ░░   ░                       
      ░                    ░          ░     ░  ░   ░           ░     ░  ░   ░                           
     ░                                                        ░                                         
'
ip=$(hostname -I|cut -f1 -d ' ')
echo "your Server IP address is:$ip"

echo -e "\e[5m\e[92mInstalling gnutls-bin"

apt install gnutls-bin
mkdir certificates
cd certificates

cat << EOF > ca.tmpl
cn = "VPN CA"
organization = "Big Corp"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF

certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem

cat << EOF > server.tmpl
#yourIP
cn=$ip
organization = "my company"
expiration_days = 3650
signing_key
encryption_key
tls_www_server
EOF

certtool --generate-privkey --outfile server-key.pem
certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

echo -e "\e[5m\e[92mInstall ocserv"
apt install ocserv
cp /etc/ocserv/ocserv.conf ~/certificates/
pass="passwd=/etc/ocserv/ocpasswd"
sed -i -e 's@auth = "plain@#auth@g' /etc/ocserv/ocserv.conf
sed -i -e 's@try-mtu-discovery = @try-mtu-discovery = true @g' /etc/ocserv/ocserv.conf
sed -i -e 's@dns = @dns = 8.8.8.8@g' /etc/ocserv/ocserv.conf
sed -i -e 's@route =@#route =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@no-route =@#no-route =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@cisco-client-compat@cisco-client-compat = true@g' /etc/ocserv/ocserv.conf

echo "Enter a username:"
read username

ocpasswd -c /etc/ocserv/ocpasswd $username
iptables -t nat -A POSTROUTING -j MASQUERADE
sed -i -e 's@#net.ipv4.ip_forward@net.ipv4.ip_forward=1@g' /etc/ocserv/ocserv.conf

sysctl -p /etc/sysctl.conf
echo -e "\e[92mStopping ocserv service"
service ocserv stop
echo -e "\e[92mStarting ocserv service"
service ocserv start

echo "\e[32mOpenConnect Server Configured Succesfully."
