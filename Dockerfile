FROM ubuntu:16.10

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install strongswan \
      strongswan-pki \
      strongswan-plugin-farp \
      strongswan-plugin-dhcp \
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

RUN mkdir ~/pki
RUN mkdir ~/pki/cacerts
RUN mkdir ~/pki/private
RUN mkdir ~/pki/certs
RUN (chmod 700 ~/pki)
RUN (ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem)
RUN (ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem \
         --type rsa --dn "CN=VPN root CA" --outform pem > ~/pki/cacerts/ca-cert.pem)

# Generate server certificate
RUN (ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem)

RUN (ipsec pki --pub --in ~/pki/private/server-key.pem --type rsa \
        | ipsec pki --issue --lifetime 1825 \
            --cacert ~/pki/cacerts/ca-cert.pem \
            --cakey ~/pki/private/ca-key.pem \
            --dn "CN=164.92.138.94" --san "164.92.138.94" \
            --flag serverAuth --flag ikeIntermediate --outform pem \
        >  ~/pki/certs/server-cert.pem)

RUN cp -r ~/pki/* /etc/ipsec.d/

ADD ./etc/* /etc/
ADD ./bin/* /usr/bin/

VOLUME /etc
VOLUME /config

# http://blogs.technet.com/b/rrasblog/archive/2006/06/14/which-ports-to-unblock-for-vpn-traffic-to-pass-through.aspx
EXPOSE 500/udp 4500/udp

CMD /usr/bin/start-vpn
