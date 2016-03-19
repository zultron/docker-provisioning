FROM debian:jessie
MAINTAINER john@zultron.com

# Configure & update apt
ENV DEBIAN_FRONTEND noninteractive
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
        /etc/apt/apt.conf.d/01norecommend
RUN apt-get update
RUN apt-get upgrade -y
# silence debconf warnings
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y libfile-fcntllock-perl


###########################################
# Install packages

# Do it first so docker build doesn't have to reinstall each time a
# file in a COPY statement is changed
RUN apt-get install -y supervisor
RUN apt-get install -y rsyslog
RUN apt-get install -y squid-deb-proxy
RUN apt-get install -y isc-dhcp-server
RUN apt-get install -y tftpd-hpa


###########################################
# Supervisord

COPY supervisord.conf.d /etc/supervisor/conf.d
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
CMD ["/sbin/entrypoint.sh"]


###########################################
# Rsyslogd

RUN sed -i -e 's,/var/log/.*,/var/log/supervisor/syslog,' \
        /etc/rsyslog.conf


###########################################
# SQUID

# Add extra deb repos and ports to acls
RUN mv /etc/squid-deb-proxy/mirror-dstdomain.acl.d /tmp
COPY mirror-dstdomain.acl.d /etc/squid-deb-proxy/mirror-dstdomain.acl.d
RUN mv /tmp/mirror-dstdomain.acl.d/* /etc/squid-deb-proxy/mirror-dstdomain.acl.d \
        && rmdir /tmp/mirror-dstdomain.acl.d
RUN sed -i /etc/squid-deb-proxy/squid-deb-proxy.conf \
        -e '/acl Safe_ports port 443/ s/$/ 11371/'
RUN rmdir /var/log/squid-deb-proxy && \
    ln -s supervisor /var/log/squid-deb-proxy
RUN . /usr/share/squid-deb-proxy/init-common.sh && pre_start


###########################################
# DHCPD

# Install dhcpd config
COPY dhcpd.conf /etc/dhcp/dhcpd.conf
