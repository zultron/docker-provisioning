FROM debian:jessie
MAINTAINER john@zultron.com

# Configure & update apt
ENV DEBIAN_FRONTEND noninteractive
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
        /etc/apt/apt.conf.d/01norecommend
RUN apt-get update

# Install squid w/deb proxy config
RUN apt-get install -y squid-deb-proxy

# Script to run proxy and interactive shell
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

# Add extra deb repos to acls
RUN mv /etc/squid-deb-proxy/mirror-dstdomain.acl.d /tmp
COPY mirror-dstdomain.acl.d /etc/squid-deb-proxy/mirror-dstdomain.acl.d
RUN mv /tmp/mirror-dstdomain.acl.d/* /etc/squid-deb-proxy/mirror-dstdomain.acl.d \
        && rmdir /tmp/mirror-dstdomain.acl.d

# Configure run-time
EXPOSE 8000/tcp
VOLUME /var/cache/squid-deb-proxy
ENTRYPOINT ["/sbin/entrypoint.sh"]
