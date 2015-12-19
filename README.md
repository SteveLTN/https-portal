# Nginx-ACME

A Docker image with Nginx and Let's Encrypt automatic SSL configuration shipped.

DockerHub: [https://hub.docker.com/r/steveltn/nginx-acme/](https://hub.docker.com/r/steveltn/nginx-acme/)

## Warning

This project is in a very early stage. Do NOT use it in production!

## Introduction

Nginx-ACME is a Docker container with Nginx installed, together with an ACME client to obtain free SSL certificates from [Let's Encrypt](https://letsencrypt.org) automatically.

It:

* obtains an SSL certificate for each of your subdomains from [Let's Encrypt](https://letsencrypt.org)
* configures Nginx to use HTTPS (and force HTTPS by redirecting HTTP to HTTPS)
* sets up a cron job that checks your certificates every week, and renew them if they expire in 30 days

This project includes a copy of the fantastic project [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler. Thank you Daniel!

## About Rate Limits of Let's Encrypt

Let's Encrypt is in public beta at the moment. According to [this](https://community.letsencrypt.org/t/public-beta-rate-limits/4772) and [this discussion](https://community.letsencrypt.org/t/public-beta-rate-limits/4772/42), the rate limit is

* 10 registrations per IP per 3 hours
* 5 certificates per domain (not subdomain) per 7 days

The former is not usually a problem, however the latter could be if you want to use multiple subdomains on a single domain. Let's Encrypt does support SAN certificates, however it requires careful planning and is hard to automate. So in Nginx-ACME we only deal with CN certificates.

The image stores your certificates in a data volume and will not re-sign certificates until 30 days before expiration if one exists (you can force renew certificates by using `FORCE_RENEW=true` environment variable). However if you play around with the image a lot, you can hit the limit. That's why `PRODUCTION` flag is off by default, and we use the Let's Encrypt staging server. When you feel everything is good, you can set `PRODUCTION=true` as an environment variable.

Let's Encrypt says the restrict will be loosen as the beta goes.

## Getting Started

If you are not familiar with `docker-compose`, I recommend you read [this blog post](http://steveltn.me/blog/2015/12/18/nginx-acme/), it is a step-by-step guide showing you how to set up a WordPress using Nginx-ACME.

## Simple Configuration

Set up ssl for `example.com` and forward the requests to `upstream`, run:

```
docker run -p 80:80 -p 443:443 -e "DOMAINS=example.com->http://upstream" steveltn/nginx-acme
```
You can also set up SSL for non-dockerized web services or containers that are not linked with Nginx-ACME. The Docker host machine is available as upstread `dockerhost`. For example, if you have a Rails application running of port `3000` on the host:

```
docker run -p 80:80 -p 443:443 -e "DOMAINS=example.com->http://dockerhost:3000" steveltn/nginx-acme
```

Nginx-ACME supports multiple domains. A single-domain certificate will be obtained for each given domain.

```
docker run -p 80:80 -p 443:443 \
	-e "DOMAINS=example1.com -> http://upstream1, example2.com -> http://upstream2" \
	steveltn/nginx-acme
```

You can mount a folder on the host machine to store keys and certificates:

```
docker run -p 80:80 -p 443:443 \
	-e "DOMAINS=example.com->http://upstream" \
	-v /path/to/certs:/var/lib/nginx-acme \
	steveltn/nginx-acme
```
Even if you don't mount volume to `/var/lib/nginx-acme`, this folder is a data volume. You can run `docker inspect <container>` to find the volume on the host filesystem.

## Customizing Nginx Configurations

If you want to set up your own Nginx configuration, you can build another image on top of Nginx-ACME. All you need to do is to add your nginx configurations to `/var/lib/nginx-conf` folder inside the container.

For a domain `example.com`, Nginx-ACME will first try to use `example.com.conf` and `example.com.ssl.conf`. If not found, `default.conf` and `default.ssl.conf` will be used instead. You can override the defaults as well. The default files can be found [here](https://github.com/SteveLTN/nginx-acme/tree/master/nginx-conf).

When you do experiments, please do not turn on `PRODUCTION` flag to prevent you from hitting the rate limit of Let's Encrypt.

The Nginx config template files will be parsed by [ERB](http://www.stuartellis.eu/articles/erb/) for each domain. The ERB tags will be replaced accordingly. Currently there are a few helpers available:

* `<%= domain.name %>`
* `<%= domain.upstream %>`
* `<%= domain.chained_cert_path %>`
* `<%= domain.key_path %>`
* `<%= acme_challenge_location %>`
* `<%= dhparam_path %>`

Please see the examples [here](https://github.com/SteveLTN/nginx-acme/tree/master/examples/custom_config).
