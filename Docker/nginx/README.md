Nginx
===
## 简介
* **nginx** 是一个HTTP和反向代理服务器，一个邮件代理服务器和一个通用的TCP/UDP代理服务器。
> * 官方站点：https://nginx.org/en/


## Example:
### 七层

	#运行一个FCGI模式实例
	docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/www:/usr/local/nginx/html -e FCGI_SERVER="php.redhat.xyz|192.17.0.5:9000" --hostname php --name php jiobxn/nginx

	#运行两个JAVA_PHP模式实例
	docker run -d --restart always -p 10081:80 -p 10441:443 -v /docker/webapps:/usr/local/nginx/html -e JAVA_PHP_SERVER="java.redhat.xyz|172.17.0.6:8080" --hostname java --name java jiobxn/nginx

	docker run -d --restart always -p 10082:80 -p 10442:443 -v /docker/www:/usr/local/nginx/html -e JAVA_PHP_SERVER="apache.redhat.xyz|172.17.0.7" --hostname apache --name apache jiobxn/nginx

	#运行一个PROXY模式实例
	docker run -d --restart always -p 10083:80 -p 10443:443 -e PROXY_SERVER="g.redhat.xyz|www.google.co.id%backend_https=y" --hostname google --name proxy jiobxn/nginx

	#运行一个DOMAIN模式实例
	docker run -d --restart always -p 10084:80 -p 10444:443 -e DOMAIN_PROXY="fqhub.com%backend_https=y" --hostname fqhub --name nginx jiobxn/nginx

四种模式可以一起用，需要使用"root=project_directory"区分不同项目目录

### 四层

	#运行一个TCP模式实例
	docker run -d --restart always -p 3306:3306 --network=mynetwork --ip=10.0.0.2 -e STREAM_SERVER="3306|10.0.0.63:3306&backup,10.0.0.62:3306,10.0.0.61:3306%stream_lb=least_conn" --hostname nginx-tcp --name nginx-tcp nginx

七层负载均衡和四层负载均衡，在一个容器中只能有一种存在


### 高可用

    docker run -d --privileged --network=mynetwork --ip=10.0.0.10 -e PROXY_SERVER="10.0.0.31,10.0.0.32,10.0.0.33,10.0.0.34" -e KP_VIP=10.0.0.1 --name nginx1 nginx
    docker run -d --privileged --network=mynetwork --ip=10.0.0.20 -e PROXY_SERVER="10.0.0.31,10.0.0.32,10.0.0.33,10.0.0.34" -e KP_VIP=10.0.0.1 --name nginx2 nginx


***

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数



基本选项：不同工作模式，每个独立的站点以";"为分隔符

	#HTTP
	FCGI_SERVER=<php.jiobxn.com|192.17.0.5:9000[%<Other options>]>
	JAVA_PHP_SERVER=<tomcat.jiobxn.com|192.17.0.6:8080[%<Other options>];apache.jiobxn.com|192.17.0.7[%<Other options>]>
	PROXY_SERVER=<g.jiobxn.com|www.google.co.id.hk%backend_https=Y>
	DOMAIN_PROXY=<fqhub.com%backend_https=Y>

	#TCP/UDP
	STREAM_SERVER=<22|102.168.0.242:22;53|8.8.8.8:53%udp=Y>

	#Keepalived
	KP_VIP=<virtual address>    #要使用keepalived需要root权限 --privileged

默认选项：

	#HTTP
	DEFAULT_SERVER=<jiobxn.com>						#在多个站点中选择一个默认站点，IP访问的站点
	NGX_PASS=[jiobxn.com]							# /nginx_status 密码
	NGX_USER=<nginx>							# /nginx_status 用户名，默认为空
	NGX_CHARSET=[utf-8]							#字符集
	FCGI_PATH=[/var/www]							#fcgi工作目录
	HTTP_PORT=[80]								#http端口
	HTTPS_PORT=[443]							#https端口
	SSL_CACHE=[10m]								#ssl session缓存大小(1m是4000连接)
	DOMAIN_TAG=[888]							#域名混淆字符，用于DOMAIN_PROXY模式
	EOORO_JUMP=[https://cn.bing.com]					#错误跳转，用于DOMAIN_PROXY模式
	NGX_DNS=[9.9.9.9]							#DNS，用于DOMAIN_PROXY模式
	CACHE_TIME=[10m]							#缓存时间，默认10分钟
	CACHE_SIZE=[2g]								#用于缓存的磁盘大小
	CACHE_MEM=[server memory 10%]						#用于缓存的内存大小
	ACCLOG_OFF=<Y>								#关闭访问日志记录
	ERRLOG_OFF=<Y>								#关闭错误日志记录
	KP_ETH=[default interface]						#用于组播的网络接口
	KP_VRID=[77]								#路由ID
	KP_PASS=[Newpa55]							#认证密码

	#HTTP 子选项：作用于四种工作模式，与基本选项之间以"%"为分隔符，各子选项之间用","为分隔符，参数之间用"|"为分隔符，用于替换某种模式下的默认选项
		alias=</boy|/mp4>						#别名目录，别名/boy 容器目录/mp4，用于FCGI、JAVA_PHP和PROXY
		root=<wordpress>						#网站根目录，html/wordpress
		http_port=<8080>						#HTTP端口
		https_port=<8443>						#HTTPS端口
		crt_key=<jiobxn.crt|jiobxn.key>					#SSL证书，在/key目录下
		http2=<Y>							#启用http2
		full_https=<Y>							#全站HTTPS，http跳转到https
		charset=<gb2312>						#字符集
		cache=<Y>							#启用缓存
		header=<host>							#上游主机头，FCGI和JAVA_PHP是host，PROXY和DOMAIN是proxy_host
		http_lb=<ip_hash|hash|least_conn>				#负载均衡模式
		backend_https=<Y>						#上游HTTPS，用于PROXY和DOMAIN模式
		dns=<223.5.5.5>							#DNS，用于DOMAIN模式
		tag=<9999>							#域名混淆字符，用于DOMAIN模式
		error=<https://www.bing.com>					#错误跳转，用于DOMAIN模式
		auth=<admin|passwd>						#用户认证，用于PROXY和DOMAIN模式
		filter=<.google.com|.fqhub.com&.twitter.com|.fqhubcom>		#字符替换，用于PROXY和DOMAIN模式
		log=<N|Y>							#使用独立日志文件，或者关闭日志

	#TCP/UDP 子选项
		stream_lb=<hash|least_conn>					#负载均衡模式
		conn_timeout=[1m]						#后端连接超时，默认1分钟
		proxy_timeout=[10m]						#空闲超时，默认10分钟
		udp=<Y>								#UDP

****

关于日志记录客户端真实IP(nginx proxy)

    sed -i 's/$remote_addr/$proxy_add_x_forwarded_for/' /etc/nginx/nginx.conf

****

关闭IE浏览器证书检查

    Internet选项-->高级-->安全-->对证书地址不匹配发出警告(取消勾选)
    Internet选项-->安全-->Internet-->自定义级别-->其他-->显示混合内容(启用)

****

### docker hub proxy

**准备工具**

    ~]# cat crt.sh
    #!/bin/bash
    [ ! -f ca.crt -o ! -f ca.key ] && openssl req -newkey rsa:4096 -nodes -sha256 -keyout ca.key -x509 -days 3650 -out ca.crt -subj "/C=CN/L=London/O=Company Ltd/CN=nginx-docker"
    
    for i in $(echo $1 |sed 's/,/ /g');do
     if [ ! -f "$i.crt" -o ! -f "$i.key" ]; then
        openssl req -newkey rsa:4096 -nodes -sha256 -keyout $i.key -out $i.csr -subj "/C=CN/L=London/O=Company Ltd/CN=$i"
        openssl x509 -req -days 3650 -in $i.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $i.crt
     fi
        echo "$i|$i%backend_https=y,crt_key=$i.crt|$i.key"
    done
    echo

**创建证书**

    echo "k8s.gcr.io,dl.k8s.io,get.k8s.io,gcr.io,storage.googleapis.com,packages.cloud.google.com,auth.docker.io,dseasb33srnrn.cloudfront.net,registry-1.docker.io" >crt.txt
    bash crt.sh $(cat crt.txt) | tr '\n' ';' | sed 's/;;/\n/' | tee domain.txt

**proxy模式**

    docker run -d --restart unless-stopped --network host -v /docker/key:/key -e PROXY_SERVER="$(cat domain.txt)" --name nginx-k8s jiobxn/nginx:rpm

**客户端修改hosts**

    echo "<ip-address> k8s.gcr.io dl.k8s.io get.k8s.io gcr.io storage.googleapis.com packages.cloud.google.com auth.docker.io dseasb33srnrn.cloudfront.net registry-1.docker.io" >>/etc/hosts

**添加CA证书信任**

    curl -s http://x.x.x.x/ca.crt >> /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
    systemctl restart docker.service

注意：worker_processes数越大占用内存越多
