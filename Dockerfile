FROM ubuntu:18.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install strongswan \
      strongswan-pki \
      iptables \
      uuid-runtime \
      ndppd \
      openssl \
      bash \
      vim \
    && rm -rf /var/lib/apt/lists/* # cache busted 20160406.1

RUN rm /etc/ipsec.secrets
RUN mkdir /config
RUN (cd /etc && ln -s /config/ipsec.secrets .)

RUN (mkdir -p ~/pki/{cacerts,certs,private})
RUN (chmod 700 ~/pki)
RUN (ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem)
RUN (ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem \
         --type rsa --dn "CN=VPN root CA" --outform pem > ~/pki/cacerts/ca-cert.pem)

RUN (ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem)

ADD ./etc/* /etc/
ADD ./bin/* /usr/bin/

VOLUME /etc
VOLUME /config

# http://blogs.technet.com/b/rrasblog/archive/2006/06/14/which-ports-to-unblock-for-vpn-traffic-to-pass-through.aspx
EXPOSE 500/udp 4500/udp

CMD /usr/bin/start-vpn
