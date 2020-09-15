FROM alpine:3.12 as build

WORKDIR /build

ENV NGINX_VERSION 1.19.2

RUN wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
RUN tar xf nginx-$NGINX_VERSION.tar.gz && mv nginx-$NGINX_VERSION nginx

# at https://github.com/rinsuki/nginx-rtmp-module/tree/rinsuki-master
ENV NGINX_RTMP_VERSION 2f1a34c13eee7e584c2691259707aab9f37c2f35

RUN wget https://github.com/rinsuki/nginx-rtmp-module/archive/$NGINX_RTMP_VERSION.tar.gz
RUN tar xf $NGINX_RTMP_VERSION.tar.gz && mv nginx-rtmp-module-$NGINX_RTMP_VERSION nginx-rtmp-module

WORKDIR /build/nginx

RUN apk --no-cache add g++ pcre-dev openssl-dev make
RUN ./configure --add-module=/build/nginx-rtmp-module --prefix=/nginx --without-http_gzip_module && make -j4 && make install

FROM alpine:3.12

LABEL org.opencontainers.image.source https://github.com/rinsuki/rtmp-station

RUN apk --no-cache add pcre openssl ffmpeg rtmpdump
COPY --from=build /nginx /nginx

RUN ln -sf /dev/stdout /nginx/logs/access.log && ln -sf /dev/stderr /nginx/logs/error.log

COPY conf/nginx.conf /nginx/conf/
COPY conf/conf.d /nginx/conf/conf.d

STOPSIGNAL SIGTERM
CMD ["/nginx/sbin/nginx", "-g", "daemon off;"]