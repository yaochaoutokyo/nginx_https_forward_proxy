# Overview

This repo is the Dockerfile of a transparent https forward proxy built with nginx.

# Get start
```
docker build -t nginx_https_forward_proxy .
docker run -d -p 443:443 --restart=always nginx_https_forward_proxy
```

# Technical Details

Create L4 Nginx forward proxy, using ssl_preread module to get host name from SNI of clients' HTTPS request, Nginx configuration is as follows
```
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}

# use stream context, which is working on tcp layer
stream {
    resolver 8.8.8.8;
    server {
        listen 443;
        # open ssl_preread module
        ssl_preread on;
        proxy_connect_timeout 5s;
        # read host name from SNI of original request, proxy to the hostname and port 
        proxy_pass $ssl_preread_server_name:$server_port;
    }
}
```
Notice, to enable stream and  ssl_preread module, you need to build Nginx with options 
```
--with-stream \
--with-stream_ssl_preread_module \
--with-stream_ssl_module
```
In our case, we build Nginx with following command
```
wget http://nginx.org/download/nginx-1.19.6.tar.gz
tar -zxf nginx-1.19.6.tar.gz
cd nginx-1.19.6
./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx --with-file-aio --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-threads --with-stream --with-stream_ssl_preread_module --with-stream_ssl_module
make install
```

# How to use
1. Use hostAlias to overwrite the IP of the domain you want to access through proxy, for example, replace the IP of api.twilio.com with forward proxy IP 47.74.8.95

```
...      
      hostAliases:
      - hostnames:
        - api.twilio.com
        ip: 47.74.8.95
...
```

2. Confirm the proxy is working, notice that curl https://api.twilio.com -svo /dev/null is trying to access proxy IP 47.74.8.95, instead of the real IP of api.twilio.com
```
# curl https://api.twilio.com -svo /dev/null
* Rebuilt URL to: https://api.twilio.com/
*   Trying 47.74.8.95...
* TCP_NODELAY set
* Connected to api.twilio.com (47.74.8.95) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
...
```

Reference

1. [How to Use NGINX as an HTTPS Forward Proxy Server](https://www.alibabacloud.com/blog/how-to-use-nginx-as-an-https-forward-proxy-server_595799)

2. [Adding entries to Pod /etc/hosts with HostAliases](https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/)
