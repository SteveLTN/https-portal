From nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

RUN mkdir -p /var/www/challenges/
RUN apt-get update && \
    apt-get install -y python ruby vim wget cron && \
    rm -rf /var/lib/apt/lists/*

ADD ./acme_tiny.py /usr/local/bin/
ADD ./renew.sh /etc/cron.monthly/renew_certificates
ADD ./init.sh /usr/local/bin/

RUN chmod a+x /usr/local/bin/acme_tiny.py
RUN chmod a+x /etc/cron.monthly/renew_certificates
RUN chmod a+x /usr/local/bin/init.sh

ADD ./nginx-conf /root/nginx-conf

CMD init.sh
