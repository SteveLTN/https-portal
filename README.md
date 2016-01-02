# Nginx-ACME

Nginx-ACME is a fully automated HTTPS server powered by
[Nginx](http://nginx.org), [Let's Encrypt](https://letsencrypt.org) and

[Docker](https://www.docker.com). By using it, you can run any existing web
application over HTTPS, with only one extra line of configuration.

The SSL certificates are obtain, and renew from Let's Encrypt automatically.

Docker Hub page:
[https://hub.docker.com/r/steveltn/nginx-acme/](https://hub.docker.com/r/steveltn/nginx-acme/)

## Warning

This project is in active development stage. Use it in production with CAUTION.

## Quick Start

Nginx-ACME shipped as a Docker image, so before use it, you need a Linux
machine (either local or remote host) with Docker installed. We recommand use
[Docker Compose](https://docs.docker.com/compose/) to run it. Create a
`docker-compose.yml` file with the following content in any directory:

```yaml
nginx-acme:
  image: steveltn/nginx-acme
  ports:
    - 80:80
    - 443:443
  links:
    - wordpress
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress'
    # PRODUCTION: 'true'
    # FORCE_RENEW: 'true'

wordpress:
  image: wordpress
  links:
    - db:mysql

db:
  image: mariadb
  environment:
    MYSQL_ROOT_PASSWORD: 'a secure password'
```

Then run `docker-compose up` command in the same directory, moment later
you'll get a WordPress running on
[https://wordpress.example.com](https://wordpress.example.com).

In the above example, only environment variables under `nginx-acme` section are Nginx-ACME specific configurations.

Note: `PRODUCTION` flag is `false` by default, which results in a test
(untrusted) certificate from Let's Encrypt.

## Minimal Setup

In case you simply want to quickly get a running HTTPS server, you can use the following `docker-compose.yml` file:

```yaml
nginx-acme:
  image: steveltn/nginx-acme
  ports:
    - 80:80
    - 443:443
  environment:
    DOMAINS: 'example.com'
    # PRODUCTION: 'true'
```

Then run `docker-compose up`, now you'll have a welcome page running in
[https://example.com](https://example.com).

## Features

### Automatic Container Discovery

### Hybrid Setup with Non-Dockerized Apps

### Multiple Domains

You can specify multiple domains by splitting them with comma:

```yaml
nginx-acme:
  # ...
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress, gitlab.example.com
    -> http://gitlab'
```

### Share Certificates with Other Apps

You can mount an arbitrary host directory to `/var/lib/nginx-acme` as a
[data volume](https://docs.docker.com/engine/userguide/dockervolumes/).

```yaml
nginx-acme:
  # ...
  volumes:
    - /data/ssl_certs:/var/lib/nginx-acme
```

Now your certificates are available in `/data/ssl_certs` of your Docker
host.

## Advanced Usage: Customizing Nginx Configurations

You can provide a config segament of nginx.conf which contain a valid
`server` block.

## How It Works

It:

* obtains an SSL certificate for each of your subdomains from [Let's Encrypt](https://letsencrypt.org)
* configures Nginx to use HTTPS (and force HTTPS by redirecting HTTP to HTTPS)
* sets up a cron job that checks your certificates every week, and renew them if they expire in 30 days

## About Rate Limits of Let's Encrypt

Let's Encrypt is in public beta at the moment. According to
[this](https://community.letsencrypt.org/t/public-beta-rate-limits/4772) and
[this discussion](https://community.letsencrypt.org/t/public-beta-rate-limits/4772/42),
the rate limit is

* 10 registrations per IP per 3 hours.
* 5 certificates per domain (not sub-domain) per 7 days.

The former is not usually a problem, however the latter could be if you want
to use multiple sub-domains on a single domain. Let's Encrypt does support SAN
certificates, however it requires careful planning and is hard to automate. So
in Nginx-ACME we only deal with CN certificates.

Nginx-ACME stores your certificates in a data volume and will not re-sign
certificates until 30 days before expiration if one exists (you can force
renew certificates by using `FORCE_RENEW: 'true'` environment variable). However
if you play around with the image a lot, you can hit the limit. That's why
`PRODUCTION` flag is off by default, and we use the Let's Encrypt staging
server. When you feel everything is good, you can turn on the flag with
`PRODUCTION: 'true'`.

Let's Encrypt says the restrict will be loosen as the beta goes.

## Credits

* [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler.
* [docker-gen](https://github.com/jwilder/docker-gen) by Jason Wilder.
