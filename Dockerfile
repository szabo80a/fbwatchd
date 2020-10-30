FROM alpine:latest

MAINTAINER szabo80a <andy80@gmail.com>

RUN apk add bash curl jq
RUN apk add --no-cache --upgrade grep

# add local files
ADD /root /
# start the daemon
CMD /fbwatchd.sh 
