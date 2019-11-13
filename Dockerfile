FROM debian:buster

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
RUN apt-get install -y apache2


###########################################
# Supervisord

COPY supervisord/conf.d /etc/supervisor/conf.d
COPY common/entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
CMD ["/sbin/entrypoint.sh"]


###########################################
# Rsyslogd

# Dump all logs into /var/log/supervisor/syslog
RUN sed -i -e 's,/var/log/.*,/var/log/supervisor/syslog,' \
        /etc/rsyslog.conf


###########################################
# DHCPD

COPY dhcpd/supervisord-dhcpd.conf /etc/supervisor/conf.d/dhcpd.conf
COPY dhcpd/init.sh /etc/provisioning/dhcpd.init.sh
# Config file
COPY dhcpd/dhcpd.conf /etc/dhcp/dhcpd.conf
# Daemon helper script
COPY dhcpd/run-dhcpd.sh /usr/sbin/


###########################################
# TFTPD

COPY tftpd/supervisord-tftpd.conf /etc/supervisor/conf.d/tftpd.conf


###########################################
# Squid

COPY squid/supervisord-squid.conf /etc/supervisor/conf.d/squid.conf
COPY squid/init.sh /etc/provisioning/squid.init.sh
# Add custom deb repos to acls
COPY squid/mirror-dstdomain.acl.d/* /etc/squid-deb-proxy/mirror-dstdomain.acl.d/
# Add gpg key server port 11371 to acls
RUN sed -i /etc/squid-deb-proxy/squid-deb-proxy.conf \
        -e '/acl Safe_ports port 443/ s/$/ 11371/'
# Log to /var/log/supervisor
RUN sed -i /etc/squid-deb-proxy/squid-deb-proxy.conf \
        -e 's,/var/log/squid-deb-proxy,/var/log/supervisor,'

###########################################
# HTTPD

COPY httpd/supervisord-httpd.conf /etc/supervisor/conf.d/httpd.conf
# Set log directory
RUN sed -i -e 's,/var/log/.*,/var/log/supervisor,' /etc/apache2/envvars
# Set config
COPY httpd/apache2.conf /etc/apache2/sites-available/000-default.conf
