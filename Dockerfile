From nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

RUN mkdir -p /var/www/challenges/
RUN apt-get update && \
    apt-get install -y python ruby vim wget && \
    rm -rf /var/lib/apt/lists/*

ADD ./acme_tiny.py /usr/local/bin/acme_tiny

RUN chmod a+x /usr/local/bin/acme_tiny

ADD ./nginx-conf /root/nginx-conf

ADD ./init.sh /root/
RUN chmod a+x /root/init.sh

CMD /root/init.sh
