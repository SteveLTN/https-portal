# HTTPS-PORTAL

HTTPS-PORTAL is a fully automated HTTPS server powered by
[Nginx](http://nginx.org), [Let's Encrypt](https://letsencrypt.org) and
[Docker](https://www.docker.com). By using it, you can run any existing web
application over HTTPS, with only one extra line of configuration.

The SSL certificates are obtained, and renewed from Let's Encrypt automatically.

Docker Hub page:
[https://hub.docker.com/r/steveltn/https-portal/](https://hub.docker.com/r/steveltn/https-portal/)

## Warning

This project is in active development. Use it in production with CAUTION.

## Prerequisite

HTTPS-PORTAL is shipped as a Docker image. To use it, you need a Linux machine (either local or remote host) which:

* Has 80 and 443 port available and exposed.
* Has [Docker Engine](https://docs.docker.com/engine/installation/) installed. In addition, [Docker Compose](https://docs.docker.com/compose/) is highly recommended, for it makes your life easier. Examples in our documents are mainly in Docker Compose format.

Though it is good to have, knowledge about Docker is not required to use HTTPS-PORTAL.

## Quick Start

Create a `docker-compose.yml` file with the following content in any directory of your choice:

```yaml
https-portal:
  image: steveltn/https-portal
  ports:
    - '80:80'
    - '443:443'
  links:
    - wordpress
  restart: always
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress'
    PRODUCTION: 'true'
    # FORCE_RENEW: 'true'

wordpress:
  image: wordpress
  links:
    - db:mysql

db:
  image: mariadb
  environment:
    MYSQL_ROOT_PASSWORD: '<a secure password>'
```

Then run `docker-compose up` command in the same directory. Moment later
you'll get a WordPress running on
[https://wordpress.example.com](https://wordpress.example.com).

In the example above, only the environment variables under `https-portal` section
are HTTPS-PORTAL specific configurations.

Note: `PRODUCTION` flag is `false` by default, which results in a test
(untrusted) certificate from Let's Encrypt.

## Minimal Setup

In case you simply want to get a running HTTPS server with minimal effort, you can use the
following `docker-compose.yml` file:

```yaml
https-portal:
  image: steveltn/https-portal
  ports:
    - 80:80
    - 443:443
  environment:
    DOMAINS: 'example.com'
    PRODUCTION: 'true'
```

Then run `docker-compose up`, and you'll have a welcome page running in
[https://example.com](https://example.com).

## Features

### Automatic Container Discovery

### Hybrid Setup with Non-Docker Apps

### Multiple Domains

You can specify multiple domains by splitting them with commas:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress, gitlab.example.com
    -> http://gitlab'
```

### Share Certificates with Other Apps

You can mount an arbitrary host directory to `/var/lib/https-portal` as a
[data volume](https://docs.docker.com/engine/userguide/dockervolumes/).
For instance:

```yaml
https-portal:
  # ...
  volumes:
    - /data/ssl_certs:/var/lib/https-portal
```

Now your certificates are available in `/data/ssl_certs` of your Docker host.

## Advanced Usage: Customizing Nginx Configurations

You can provide a config segment of nginx.conf containing a valid
`server` block.

## How It Works

It:

* obtains an SSL certificate for each of your subdomains from
  [Let's Encrypt](https://letsencrypt.org)
* configures Nginx to use HTTPS (and force HTTPS by redirecting HTTP to HTTPS)
* sets up a cron job that checks your certificates every week, and renew them
  if they expire in 30 days

## About Rate Limits of Let's Encrypt

Let's Encrypt is in public beta at the moment. According to
[this](https://community.letsencrypt.org/t/public-beta-rate-limits/4772) and
[this discussion](https://community.letsencrypt.org/t/public-beta-rate-limits/4772/42),
the rate limit is

* 10 registrations per IP per 3 hours.
* 5 certificates per domain (not sub-domain) per 7 days.

The former is not usually a problem, however the latter could be, if you want
to apply certificates for multiple sub-domains on a single domain. Let's Encrypt does support SAN
certificates, however it requires careful planning and is hard to automate. So
in HTTPS-PORTAL we only deal with CN certificates.

HTTPS-PORTAL stores your certificates in a data volume and will not re-sign
certificates until 30 days before expiration if a valid certificate is found (you can force
renew certificates by using `FORCE_RENEW: 'true'` environment variable).
However if you play around with the image a lot, you can hit the limit. That's
why `PRODUCTION` flag is off by default, and thus we use the Let's Encrypt staging
server. When you made your experiments and feel everything is good, you can switch to production mode with
`PRODUCTION: 'true'`.

According to Let's Encrypt, the restrictions will be loosen as the beta goes.

## Credits

* [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler.
* [docker-gen](https://github.com/jwilder/docker-gen) by Jason Wilder.
