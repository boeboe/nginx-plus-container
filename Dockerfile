FROM boeboe/alpine-gcc:3.14-11.2.0 AS builder

ARG JAEGER_LIB_VERSION
ARG ZIPKIN_LIB_VERSION

RUN set -x \
    && cd /tmp && git clone https://github.com/jaegertracing/jaeger-client-cpp --branch ${JAEGER_LIB_VERSION} && cd /tmp/jaeger-client-cpp \
    && mkdir /tmp/jaeger-client-cpp/build && cd /tmp/jaeger-client-cpp/build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DJAEGERTRACING_PLUGIN=ON -DBUILD_TESTING=OFF -DHUNTER_CONFIGURATION_TYPES=Release .. \
    && make -j3 && mv libjaegertracing_plugin.so /libjaegertracing_plugin.so \
    && wget -O - https://github.com/rnburn/zipkin-cpp-opentracing/releases/download/${ZIPKIN_LIB_VERSION}/linux-amd64-libzipkin_opentracing_plugin.so.gz | \
    gunzip -c > /libzipkin_opentracing_plugin.so

FROM alpine:3.14

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

# Download certificate and key from the customer portal (https://cs.nginx.com)
# and copy to the build context
COPY nginx-repo.crt /etc/apk/cert.pem
COPY nginx-repo.key /etc/apk/cert.key

COPY --from=builder /libjaegertracing_plugin.so /usr/local/lib/libjaegertracing_plugin.so
COPY --from=builder /libzipkin_opentracing_plugin.so /usr/local/lib/libzipkin_opentracing_plugin.so

RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && nginxPackages="nginx-plus nginx-plus-module-njs nginx-plus-module-lua nginx-plus-module-xslt nginx-plus-module-geoip nginx-plus-module-image-filter nginx-plus-module-perl" \
    KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
    && apk add --no-cache --virtual .cert-deps openssl git cmake \
    && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
    && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
        echo "key verification succeeded!"; \
        mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
    else \
        echo "key verification failed!"; \
        exit 1; \
    fi \
    && apk del .cert-deps \
    && apk add -X "https://plus-pkgs.nginx.com/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
    && if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
    && if [ -n "/etc/apk/cert.key" && -n "/etc/apk/cert.pem"]; then rm -f /etc/apk/cert.key /etc/apk/cert.pem; fi \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && apk add --no-cache tzdata \
    && apk add --no-cache curl ca-certificates \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]