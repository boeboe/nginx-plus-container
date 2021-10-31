# An Alpine Docker image with Nginx Plus and useful integrations

This image is based on Alpine Linux image and contains Nginx+ and the following integrations:

 - module-njs 
 - module-lua 
 - module-xslt 
 - module-geoip 
 - module-image-filter 
 - module-perl
 - module-prometheus
 - module-headers-more
 - module-opentracing
 - jaeger tracing library (v0.8.0)
 - zipkin tracing library (v0.5.2)

## Docker Hub images

You will need to build the docker image yourself, as you need an Nginx+ license. Download certificate and key from 
the customer portal (https://cs.nginx.com) and copy them to the root of this repo.

```
# ls nginx-repo.*

nginx-repo.crt
nginx-repo.key
```

## Build image

Adjust the Makefile parameters according to your needs and build and release as desired.

```
$ make
help                           This help
build                          Build the container
publish                        Tag and publish container
release                        Make a full release 
```