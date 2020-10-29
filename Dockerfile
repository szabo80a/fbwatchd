FROM alpine:latest

MAINTAINER szabo80a <andy80@gmail.com>

RUN apk add bash curl jq

COPY /root /
CMD /fbwatchd.sh 
