OpenVPN
===

## Example:

    docker run -d --restart always --privileged -v /docker/openvpn:/key -p 1194:1194 --hostname openvpn --name openvpn openvpn

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always --privileged \\
			-v /docker/openvpn:/key \\
			-p 1194:1194 \\
			-p <80:80> \\
			-e TCP_UDP=[tcp] \\    默认使用TCP
			-e TAP_TUN=[tun] \\    默认使用tun
			-e VPN_PORT=[1194] \\  默认端口
			-e VPN_USER=<jiobxn> \\  VPN用户名
			-e VPN_PASS=<123456> \\  VPN密码，默认随机
			-e MAX_CLIENT=[5] \\     最大客户端数
			-e C_TO_C=[Y] \\         允许客户端与客户端之间通信
			-e GATEWAY_VPN=[Y] \\    默认VPN做网关
			-e SERVER_IP=[SERVER_IP] \\  默认是服务器公网IP
			-e IP_RANGE=[10.8.0] \\      分配的IP地址池
			-e PROXY_USER=<jiobxn> \\    http代理用户名
			-e PROXY_PASS=<123456> \\    代理密码，默认随机
			-e PROXY_PORT=<80> \\        代理端口
			-e DNS1=[8.8.4.4] \\         默认DNS
			-e DNS2=[8.8.8.8] \\
			--hostname openvpn \\
			--name openvpn openvpn

### IOS Client:

    1.到App Store 安装OpenVPN.
    2.用iTunes 导入ta.key、auth.txt和client.ovpn 到OpenVPN

### Linux Client:

    1.安装 yum -y install openvpn
    2.传输文件 scp OpenVPN-Server-IP:/etc/openvpn/easy-rsa/2.0/keys/keys/{ta.key,auth.txt,client.conf} /etc/openvpn/
    3.启动 systemctl start openvpn@client.service

### Windows Client:

    1.下载并安装 http://swupdate.openvpn.org/community/releases/openvpn-install-xx-xx-xx.exe
    2.将ta.key、auth.txt和client.ovpn拷贝到"C:\Program Files\OpenVPN\config\"
