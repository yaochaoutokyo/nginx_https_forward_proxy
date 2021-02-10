FROM centos:7
WORKDIR /forward_proxy

# install dependencies
RUN yum update -y \
    && yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel \
    && yum clean all

# add user nginx:nginx
RUN groupadd nginx \
    && useradd -m nginx -g nginx

# download nginx, configure and install it
RUN curl -Ls http://nginx.org/download/nginx-1.19.6.tar.gz | tar -zx \
    && cd nginx-1.19.6 \
    && ./configure --prefix=/usr/share/nginx \
       --sbin-path=/usr/sbin/nginx \
       --modules-path=/usr/lib64/nginx/modules \
       --conf-path=/etc/nginx/nginx.conf \
       --error-log-path=/var/log/nginx/error.log \
       --http-log-path=/var/log/nginx/access.log \
       --http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
       --http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
       --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
       --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
       --http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
       --pid-path=/run/nginx.pid \
       --lock-path=/run/lock/subsys/nginx \
       --user=nginx \
       --group=nginx \
       --with-file-aio \
       --with-http_ssl_module \
       --with-http_stub_status_module \
       --with-http_realip_module \
       --with-threads \
       --with-stream \
       --with-stream_ssl_preread_module \
       --with-stream_ssl_module \
    && make install

# copy nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

# run nginx as a foreground process, to avoid the quitting of container after execute nginx command
# refer https://stackoverflow.com/questions/18861300/how-to-run-nginx-within-a-docker-container-without-halting
CMD ["nginx", "-g", "daemon off;"]