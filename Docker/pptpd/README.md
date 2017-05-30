PPTPD
===

## Example:

    docker run -d --restart always --privileged --network=host -e VPN_PASS=123456 --hostname=pptpd --name=pptpd jiobxn/pptpd

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always --privileged \\
			-v /docker/pptpd:/key \\
			--network=host \\         使用宿主机网络
			-e VPN_USER=[jiobxn] \\   VPN用户名
			-e VPN_PASS=<123456> \\   VPN密码，默认随机
			-e IP_RANGE:=[10.9.0] \\  分配的IP地址池
			--hostname=pptpd --name=pptpd pptpd
