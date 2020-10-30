# watching fritzbox for sip-failure and reboot fb

config file to set up Fritz!Box IP, credentials, watch interval and retry:
./fbwatchd/fbwatchd.cfg

Default:

FRITZIP="192.168.178.1"
FRITZUSER="user"
FRITZPW="password"
INTERVAL=300   # watch interval for checking sip state
RETRY=6        # retry counter 




docker run command:

docker run -v ./fbwatchd/fbwatcohd.cfg:/etc/fbwatchd.cfg --name fbwatchd aszabo/fbwatchd

