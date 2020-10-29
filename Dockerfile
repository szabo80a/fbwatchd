FROM alpine:latest

MAINTAINER szabo80a <andy80@gmail.com>

RUN apk add bash curl jq
RUN apk add --no-cache --upgrade grep

COPY /root /
CMD /fbwatchd.sh 
