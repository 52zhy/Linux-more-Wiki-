DNSCrypt
===
## 简介
* **DNSCrypt** 是一种用于保护客户端和DNS解析器之间的通信的协议，使用高速高安全性的椭圆曲线加密技术。
> * 服务器项目：https://github.com/Cofyc/dnscrypt-wrapper
> * 客户端项目：https://github.com/jedisct1/dnscrypt-proxy
> * 公共DNS列表：https://github.com/jedisct1/dnscrypt-proxy/blob/master/dnscrypt-resolvers.csv
> * BIND ebook：http://www.zytrax.com/books/dns/
> * 客户端下载：[Windows 32](https://codeload.github.com/lixuy/dnscrypt-winclient/zip/master) 、 [Windows 32](https://download.dnscrypt.org/dnscrypt-proxy/LATEST-win32-full.zip) 、 [Windows 64](https://download.dnscrypt.org/dnscrypt-proxy/LATEST-win64-full.zip)


## Example:

    #运行一个bind服务器
    docker run -d --restart unless-stopped -p 53:53/udp --name dns jiobxn/dnscrypt

    #运行一个dnscrypt服务器
    docker run -d --restart unless-stopped -p 5443:5443/udp -e SERVER_UPSTREAM=8.8.8.8:53 -e SERVER_DOMAIN=jiobxn.com --name dns jiobxn/dnscrypt
    docker logs dns

    #运行一个dnscrypt客户端
    docker run -d --restart unless-stopped -p 53:53/udp -e CLIENT_UPSTREAM=jiobxn.com:5443 -e SERVER_DOMAIN=jiobxn.com -e PROVIDER_KEY=<Provider public key> --name dns jiobxn/dnscrypt 

    #运行一个dnscrypt客户端，连接到cisco的公共DNS服务器(标准端口443)
    docker run -d --restart unless-stopped -p 53:53/udp -e CLIENT_UPSTREAM=CISCO --name dns jiobxn/dnscrypt 

    #运行一个ChinaDNS
    docker run -d --restart unless-stopped -p 53:53/udp -e CLIENT_UPSTREAM=CISCO -e CHINADNS=Y --name dns jiobxn/dnscrypt

    #在Windows上运行一个dnscrypt客户端，连接到cisco的公共DNS服务器(将本地DNS改为127.0.0.1)
    ./dnscrypt-proxy.exe --local-address=0.0.0.0:53  --resolver-address=208.67.220.220 --provider-name=2.dnscrypt-cert.opendns.com --provider-key=B735:1140:206F:225D:3E2B:D822:D7FD:691E:A1C3:3CC8:D666:8D0C:BE04:BFAB:CA43:FB79

    #测试
    docker exec -it dns dig @27.0.0.1 -p 53 google.com


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d \\
				-v /docker/dnscrypt:/key \\
				-p 5443:5443/udp \\
				-p 53:53/udp \\
				-e CERT_DAY=[365] \\                         证书有效期(天)
				-e SERVER_DOMAIN=<jiobxn.com> \\             服务器域名，可以任意指定，但是客户端与服务器必须相同
				-e SERVER_LISTEN=[0.0.0.0:5443] \\           服务器监听地址和端口
				-e SERVER_UPSTREAM=<8.8.8.8:53> \\           上上游服务器地址和端口。公共DNS或者127.0.0.1:53(记录日志)
				-e CLIENT_LISTEN=[0.0.0.0:53] \\             客户端监听地址和端口
				-e CLIENT_UPSTREAM=<server_address:port | CISCO | HOME> \\  上游服务器地址和端口
				-e PROVIDER_KEY=<Provider public key>         Provider public key
				-e CHINADNS=<Y> \\                            ChinaDNS，智能解析
				-e BIND_VERSION=["windows 2003 DNS"] \\       自定义DNS版本
				-e BIND_LOG_SIZE=[100m] \\                    日志文件大小
				-e BIND_LISTEN=["any;"] \\                     bind监听地址，注意有";"
				-e BIND_ALLOW_QUERY=["any;"] \\                允许所有客户端地址查询，注意有";"
				-e BIND_FORWARDERS=<8.8.8.8;> \\               转发DNS，不能有端口号，注意有";"
				-e BIND_FORWARD_ONLY=<Y> \\                    只使用转发DNS，不递归查询
				-e BIND_CACHE_SIZE=[32m] \\                    dns缓存大小
				-e BIND_QUERY_LOG=<Y> \\                       记录解析日记
				--hostname dns --name dns dnscrypt
