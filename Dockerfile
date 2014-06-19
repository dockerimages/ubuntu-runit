FROM dockerimages/ubuntu-baseimage
################## System Services

## Install init process.
ADD /my_init /sbin/my_init

RUN mkdir -p /etc/my_init.d && \
    mkdir -p /etc/container_environment && \
    touch /etc/container_environment.sh && \
    touch /etc/container_environment.json && \
    chmod 700 /etc/container_environment && \
    chmod 600 /etc/container_environment.sh /etc/container_environment.json

## Install runit.
RUN apt-get --no-install-recommends install -y runit

## Install a syslog daemon.
RUN apt-get --no-install-recommends install -y syslog-ng-core && \
    mkdir /etc/service/syslog-ng && \
    cp /build/runit/syslog-ng /etc/service/syslog-ng/run && \
    mkdir -p /var/lib/syslog-ng && \
    cp /build/config/syslog_ng_default /etc/default/syslog-ng

# Replace the system() source because inside Docker we
# can't access /proc/kmsg.
RUN sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf

## Install logrotate.
RUN apt-get --no-install-recommends install -y logrotate

## Install the SSH server.
RUN apt-get --no-install-recommends install -y openssh-server && \
    mkdir /var/run/sshd && \
    mkdir /etc/service/sshd && \
    cp /build/runit/sshd /etc/service/sshd/run && \
    cp /build/config/sshd_config /etc/ssh/sshd_config && \
    cp /build/00_regen_ssh_host_keys.sh /etc/my_init.d/ && \

## Install default SSH key for root and app.
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    chown root:root /root/.ssh && \
    cp /build/insecure_key.pub /etc/insecure_key.pub && \
    cp /build/insecure_key /etc/insecure_key && \
    chmod 644 /etc/insecure_key* && \
    chown root:root /etc/insecure_key* && \
    cp /build/enable_insecure_key /usr/sbin/

## Install cron daemon.
RUN apt-get --no-install-recommends install -y cron && \
    mkdir /etc/service/cron && \
    cp /build/runit/cron /etc/service/cron/run


####################### Utils
## Often used tools.
RUN apt-get --no-install-recommends install -y curl less nano vim psmisc git wget curl

## This tool runs a command as another user and sets $HOME.
ADD /setuser /sbin/setuser

####################### Cleanup
## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
RUN rm -f /etc/cron.daily/standard
