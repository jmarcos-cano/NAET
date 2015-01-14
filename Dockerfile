FROM ubuntu:14.04
MAINTAINER <marcos cano jmarcos.cano@gmail.com>


RUN apt-get update 
RUN apt-get install -y iperf olsrd 
RUN apt-get install -y git-core 
RUN apt-get install -y make
RUN  apt-get update 
RUN apt-get install -y build-essential  gcc
#gcc 

RUN git clone git://qmp.cat/bmx6.git
RUN cd bmx6 && make && make install


ADD files/docker-naet.sh /
RUN chmod +x /docker-naet.sh
ENTRYPOINT [ "/docker-naet.sh" ]
#CMD ["-t", "BMX6"] 

#./bmx6 debug=0 dev=eth0
# olsrd -f /etc/olsrd/olsrd.conf -i eth0 -nofork
