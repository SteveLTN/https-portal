# Nginx-ACME

A Docker image with Nginx and Let's Encrypt automatic SSL configuration shipped.

DockerHub: [https://hub.docker.com/r/steveltn/nginx-acme/](https://hub.docker.com/r/steveltn/nginx-acme/)

## Warning

This project is in a very early stage. Do NOT use it in production!

## Introduction

Nginx-ACME is a Docker container with Nginx installed, together with an ACME client to obtain free SSL certificates from [Let's Encrypt](https://letsencrypt.org) automatically.

It:

* obtains an SSL certificate for each of your subdomains from [Let's Encrypt](https://letsencrypt.org)
* configures Nginx to use HTTPS
* sets up a cron job that checks your certificates every week, and renew them if they will expire in 30 days

This project includes a copy of the fantastic project [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler. Thank you Daniel!

## About Rate Limits of Let's Encrypt

Let's Encrypt is in public beta at the moment. According to [this](https://community.letsencrypt.org/t/public-beta-rate-limits/4772) and [this discussion](https://community.letsencrypt.org/t/public-beta-rate-limits/4772/42), the rate limit is

* 10 registrations per IP per 3 hours
* 5 certificates per domain (not subdomain) per 7 days

The former is not usually a problem, however the latter could be if you want to use multiple subdomains on a single domain. Let's Encrypt does support SAN certificates, however it requires careful planning and is hard to automate. So in Nginx-ACME we only deal with CN certificates.

The image stores your certificates in a data volume and will not re-sign certificates until 30 days before expiration if one exists (you can force renew certificates by using `FORCE_RENEW=true` environment variable). However if you play around with the image a lot, you can hit the limit. That's why `PRODUCTION` flag is off by default, and we use the Let's Encrypt staging server. When you feel everything is good, you can set `PRODUCTION=true` as an environment variable.

Let's Encrypt says the restrict will be loosen as the beta goes.

## Simple Configuration

With simple configuration, you can easily set up your HTTPS server in seconds. HTTP requests will be redirected to HTTPS, and HTTPS requests will be forwarded to a given URL. You can set up multiple domains in simple configuration.

1. Create a Linux machine with Docker daemon installed

1. Configure your DNS server

1. Run the container. I recommend running it by using [docker-compose](https://docs.docker.com/compose/). [Here](https://github.com/SteveLTN/nginx-acme/blob/master/examples/wordpress/docker-compose.yml) is an example `docker-compose.yml` for setting up a WordPress site. If you want to set the upstream to a port on the Docker host machine, you can use `dockerhost`. It is already set up in your `/etc/hosts`.

1. Be patient. On first deploy, Nginx-acme will generate [DH parameter](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html) for SSL. This will take approx. 2 minutes. Then it is stored in a data volume, and will not require regeneration if you restart the container.

1. Visit your site in HTTPS. Since we use the staging api of Let's Encrypt, the certificate is not trusted by your browser. However you can still do a test and make sure that everything works. (See above about production rate limits)

1. Turn on the production flag by setting the environment variable `PRODUCTION=true` and restart the container.

1. Your site is ready with HTTPS!

[Here](https://github.com/SteveLTN/nginx-acme/blob/master/examples/wordpress/docker-compose.yml) is an example `docker-compose.yml` for setting up a WordPress site.

## Advanced Configuration

If you want to set up your own Nginx configuration, you can build another image on top of Nginx-ACME. All you need to do is to add your nginx configurations to `/var/lib/nginx-conf` folder inside the container.

For a domain `example.com`, Nginx-ACME will first try to use `example.com.conf` and `example.com.ssl.conf`. If not found, `default.conf` and `default.ssl.conf` will be used instead. You can override the defaults as well. The default files can be found [here](https://github.com/SteveLTN/nginx-acme/tree/master/nginx-conf).

When you do experiments, please do not turn on `PRODUCTION` flag to prevent you from hitting the rate limit of Let's Encrypt.

The Nginx config template files will be parsed by [ERB](http://www.stuartellis.eu/articles/erb/) for each domain. The ERB tags will be replaced accordingly. Currently there are a few helpers available:

* `<%= domain.name %>`
* `<%= domain.chained_cert_path %>`
* `<%= domain.key_path %>`
* `<%= acme_challenge_location %>`

Please see the examples [here](https://github.com/SteveLTN/nginx-acme/tree/master/examples/custom_config).
