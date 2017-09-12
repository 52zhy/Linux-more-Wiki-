#!/bin/bash
set -e

if [ "$1" = 'openvpn' ]; then

: ${IP_RANGE:=10.8.0}
: ${VPN_PORT:=1194}
: ${TCP_UDP:=tcp}
: ${TAP_TUN:=tun}
: ${VPN_PASS:=$(pwmake 64)}
: ${MAX_CLIENT:=5}
: ${GATEWAY_VPN:=Y}
: ${C_TO_C:=Y}
: ${PROXY_PASS:=$(pwmake 64)}
: ${PROXY_PORT:=80}
: ${DNS1:=8.8.4.4}
: ${DNS2:=8.8.8.8}


if [ -z "$(grep "redhat.xyz" /etc/openvpn/server.conf)" ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(curl -s ip.cn |egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}')
	fi

	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(curl -s myip.ipip.net |egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}')
	fi

	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	echo "Initialize openvpn"
	if [ "$(ls /key/ |egrep -c "ca.crt|ca.key|server.crt|server.key|client.crt|client.key|dh2048.pem")" -ne 7 ]; then
		#Create certificate
		cd /etc/openvpn/easy-rsa/*
		. ./vars &>/dev/null
		./clean-all --batch 2>/dev/null
		./build-ca --batch &>/dev/null
		./build-key-server --batch server 2>/dev/null
		./build-key --batch client 2>/dev/null
		./build-dh --batch 2>/dev/null
		openvpn --genkey --secret /etc/openvpn/ta.key
		
		\cp keys/*.crt /etc/openvpn/
		\cp keys/*.key /etc/openvpn/
		\cp keys/dh2048.pem /etc/openvpn/
		\cp /etc/openvpn/*.crt /key/
		\cp /etc/openvpn/*.key /key/
		\cp /etc/openvpn/dh2048.pem /key/
		\cp /etc/openvpn/ta.key /key/
	else
		\cp /key/*.crt /etc/openvpn/
		\cp /key/*.key /etc/openvpn/
		\cp /key/dh2048.pem /etc/openvpn/
		\cp /key/ta.key /etc/openvpn/
		echo "Certificate already exists, skip"
	fi
	

	# server.conf configuration file
	sed -i '1 i #redhat.xyz' /etc/openvpn/server.conf
	sed -i "s/port 1194/port $VPN_PORT/g" /etc/openvpn/server.conf
	sed -i "s/proto udp/proto $TCP_UDP/g" /etc/openvpn/server.conf
	# "dev tun" will create a routed IP tunnel. "dev tap" will create an ethernet tunnel,IOS
	sed -i "s/^dev tun/dev $TAP_TUN/g" /etc/openvpn/server.conf
	sed -i "s/server 10.8.0.0 255.255.255.0/server $IP_RANGE.0 255.255.255.0/g" /etc/openvpn/server.conf
	# Allow duplicate using a client certificate
	sed -i "s/;duplicate-cn/duplicate-cn/g" /etc/openvpn/server.conf
	sed -i "s/;max-clients 100/max-clients $MAX_CLIENT/g" /etc/openvpn/server.conf
	# BUG, [UDP]Notify the client that when the server restarts so it can automatically reconnect
	sed -i 's/explicit-exit-notify/;explicit-exit-notify/' /etc/openvpn/server.conf
	# tls-auth
	sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server.conf

	if [ "$GATEWAY_VPN" = "Y" ]; then
		sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
	else
		sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS $DNS1"\npush "route $DNS1 255.255.255.255"/g' /etc/openvpn/server.conf
		sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS $DNS2"\npush "route $DNS2 255.255.255.255"/g' /etc/openvpn/server.conf
	fi
	
	if [ "C_TO_C" = "Y" ]; then
		sed -i "s/;client-to-client/client-to-client/g" /etc/openvpn/server.conf
	fi
	

	# client.conf configuration file
	sed -i 's/;tls-auth ta.key 1/tls-auth ta.key 1/' /etc/openvpn/client.conf
	echo "ns-cert-type server" >>/etc/openvpn/client.conf
	sed -i "s/^dev tun/dev $TAP_TUN/g" /etc/openvpn/client.conf
	sed -i "s/proto udp/proto $TCP_UDP/g" /etc/openvpn/client.conf
	sed -i "s/remote my-server-1 1194/remote $SERVER_IP $VPN_PORT/g" /etc/openvpn/client.conf
	# The certificates to the client.conf
	sed -i 's/ca ca.crt/;ca ca.crt/' /etc/openvpn/client.conf
	sed -i 's/cert client.crt/;cert client.crt/' /etc/openvpn/client.conf
	sed -i 's/key client.key/;key client.key/' /etc/openvpn/client.conf
	echo -e "# ca.crt\n<ca>\n</ca>" >>/etc/openvpn/client.conf
	echo -e "# ta.key\n<tls-auth>\n</tls-auth>" >>/etc/openvpn/client.conf
	sed -i '/<ca>/ r /etc/openvpn/ca.crt' /etc/openvpn/client.conf
	sed -i '/<tls-auth>/ r /etc/openvpn/ta.key' /etc/openvpn/client.conf


	if [ $VPN_USER ]; then
		cat >/etc/openvpn/checkpsw.sh <<-END 
		#!/bin/sh
		###########################################################
		# checkpsw.sh (C) 2004 Mathias Sundman <mathias@openvpn.se>
		#
		# This script will authenticate OpenVPN users against
		# a plain text file. The passfile should simply contain
		# one row per user with the username first followed by
		# one or more space(s) or tab(s) and then the password.

		PASSFILE="/etc/openvpn/psw-file"
		LOG_FILE="/var/log/openvpn-password.log"
		TIME_STAMP=\`date "+%Y-%m-%d %T"\`

		###########################################################

		if [ ! -r "\${PASSFILE}" ]; then
			echo "\${TIME_STAMP}: Could not open password file \"\${PASSFILE}\" for reading." >> \${LOG_FILE}
			exit 1
		fi

		CORRECT_PASSWORD=\`awk '!/^;/&&!/^#/&&\$1=="'\${username}'"{print \$2;exit}' \${PASSFILE}\`

		if [ "\${CORRECT_PASSWORD}" = "" ]; then 
			echo "\${TIME_STAMP}: User does not exist: username=\"\${username}\", password=\"\${password}\"." >> \${LOG_FILE}
			exit 1
		fi

		if [ "\${password}" = "\${CORRECT_PASSWORD}" ]; then 
			echo "\${TIME_STAMP}: Successful authentication: username=\"\${username}\"." >> \${LOG_FILE}
			exit 0
		fi

		echo "\${TIME_STAMP}: Incorrect password: username=\"\${username}\", password=\"\${password}\"." >> \${LOG_FILE}
		exit 1
		END
	
		chown nobody:nobody /etc/openvpn/checkpsw.sh
		chmod u+x /etc/openvpn/checkpsw.sh
		echo "$VPN_USER       $VPN_PASS" >> /etc/openvpn/psw-file
		chmod 400 /etc/openvpn/psw-file
	
		cat >>/etc/openvpn/server.conf <<-END 
		client-cert-not-required
		#use checkpaw.sh to verify the connection client username/password
		auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env
		#The user name used to index
		username-as-common-name
		script-security 3 system
		END

		sed -i '/;key client.key/ a auth-user-pass' /etc/openvpn/client.conf
		\cp /etc/openvpn/client.conf /key/client.ovpn
		\cp /etc/openvpn/client.conf /key/client.conf
		VPN_INFO="VPN user AND password: $VPN_USER  $VPN_PASS"
	else
		echo -e "# client.crt\n<cert>\n</cert>" >>/etc/openvpn/client.conf
		echo -e "# client.key\n<key>\n</key>" >>/etc/openvpn/client.conf
		sed -i '/<cert>/ r /etc/openvpn/client.crt' /etc/openvpn/client.conf
		sed -i '/<key>/ r /etc/openvpn/client.key' /etc/openvpn/client.conf
		\cp /etc/openvpn/client.conf /key/client.ovpn
		\cp /etc/openvpn/client.conf /key/client.conf
	fi


	if [ "$PROXY_USER" ]; then
		cat >>/squid-auth.txt <<-END
		auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd 
		auth_param basic children $MAX_CLIENT 
		auth_param basic realm Squid proxy-caching web server 
		auth_param basic credentialsttl 2 hours 
		auth_param basic casesensitive off 
		acl authuser proxy_auth REQUIRED 
		http_access allow authuser
		END
	
		sed -i '/# Recommended minimum configuration:/ r /squid-auth.txt' /etc/squid/squid.conf
		echo "$PROXY_USER:$(openssl passwd -apr1 $PROXY_PASS)" > /etc/squid/passwd
		SQUID_INFO="Squid user AND password: $PROXY_USER  $PROXY_PASS"
		
		sed -i "s/http_port 3128/http_port $PROXY_PORT/" /etc/squid/squid.conf

		echo "http-proxy-retry" >>/etc/openvpn/client.conf
		echo "http-proxy $SERVER_IP $PROXY_PORT auth.txt" >>/etc/openvpn/client.conf
		#echo "http-proxy $SERVER_IP $PROXY_PORT stdin basic" >>/etc/openvpn/client.conf
		sed -i "s/proto udp/proto $TCP_UDP/g" /etc/openvpn/server.conf
		sed -i "s/remote $SERVER_IP/remote 127.0.0.1/g" /etc/openvpn/client.conf
		echo -e "$PROXY_USER\n$PROXY_PASS" >/key/auth.txt
		\cp /etc/openvpn/client.conf /key/client.ovpn
		\cp /etc/openvpn/client.conf /key/client.conf

		echo "squid" >/iptables.sh
		echo "iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $PROXY_PORT -m comment --comment OPENVPN -j ACCEPT" >>/iptables.sh
	else	
		echo "iptables -I INPUT -p $TCP_UDP -m state --state NEW -m $TCP_UDP --dport $VPN_PORT -m comment --comment OPENVPN -j ACCEPT" >/iptables.sh
	fi


	# iptables
	cat >> /iptables.sh <<-END
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -t nat -I POSTROUTING -s $IP_RANGE.0/24 -o $DEV -j MASQUERADE
	iptables -I FORWARD -s $IP_RANGE.0/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	sysctl -w net.ipv4.ip_forward=1
	END

	echo -e "$(openvpn --help |awk 'NR==1{print $1"-"$2}')" |tee /key/openvpn.log
	echo $VPN_INFO |tee -a /key/openvpn.log
	echo $SQUID_INFO |tee -a /key/openvpn.log
fi

	echo "Start ****"
	[ -z "`iptables -S |grep OPENVPN`" ] && . /iptables.sh
	exec "$@"

else

	echo -e "
	Example
			docker run -d --restart always --privileged \\
			-v /docker/openvpn:/key \\
			-p 1194:1194 \\
			-p <80:80> \\
			-e TCP_UDP=[tcp] \\
			-e TAP_TUN=[tun] \\
			-e VPN_PORT=[1194] \\
			-e VPN_USER=<jiobxn> \\
			-e VPN_PASS=<123456> \\
			-e MAX_CLIENT=[5] \\
			-e C_TO_C=[Y] \\
			-e GATEWAY_VPN=[Y] \\
			-e SERVER_IP=[SERVER_IP] \\
			-e IP_RANGE=[10.8.0] \\
			-e PROXY_USER=<jiobxn> \\
			-e PROXY_PASS=<123456> \\
			-e PROXY_PORT=<80> \\
			-e DNS1=[8.8.4.4] \\
			-e DNS2=[8.8.8.8] \\
			--hostname openvpn \\
			--name openvpn openvpn
	"
fi

#IOS Client:
# Into the App Store is installed OpenVPN.
# Use iTunes will ca.crt、client.crt、client.key、ta.key、auth.txt and client.ovpn import the to OpenVPN.

#Linux Client:
# yum -y install openvpn
# scp OpenVPN-Server-IP:/etc/openvpn/easy-rsa/2.0/keys/keys/{ca.crt,client.crt,client.key,ta.key,auth.txt,client.conf} /etc/openvpn/
# systemctl start openvpn@client.service

#Windows Client:
# download install openvpn-install-xx-xx-xx.exe for http://swupdate.openvpn.org/community/releases/
# Will ca.crt、client.crt、client.key、ta.key、auth.txt and client.ovpn import the to "C:\Program Files\OpenVPN\config\".
