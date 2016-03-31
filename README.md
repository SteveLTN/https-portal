# HTTPS-PORTAL

HTTPS-PORTAL is a fully automated HTTPS server powered by
[Nginx](http://nginx.org), [Let's Encrypt](https://letsencrypt.org) and
[Docker](https://www.docker.com). By using it, you can run any existing web
application over HTTPS, with only one extra line of configuration.

The SSL certificates are obtained, and renewed from Let's Encrypt
automatically.

Docker Hub page:
[https://hub.docker.com/r/steveltn/https-portal/](https://hub.docker.com/r/steveltn/https-portal/)

##Table of Contents

- [HTTPS-PORTAL](#https-portal)
  - [Warning](#warning)
  - [Prerequisite](#prerequisite)
  - [See It Work](#see-it-work)
  - [Quick Start](#quick-start)
  - [Features](#features)
    - [Automatic Container Discovery](#automatic-container-discovery)
    - [Hybrid Setup with Non-Dockerized Apps](#hybrid-setup-with-non-dockerized-apps)
    - [Multiple Domains](#multiple-domains)
    - [Serving Static Sites](#serving-static-sites)
    - [Share Certificates with Other Apps](#share-certificates-with-other-apps)
  - [Advanced Usage](#advanced-usage)
    - [Configure Nginx through Environment Variables](#configure-nginx-through-environment-variables)
    - [Override Nginx Configuration Files](#override-nginx-configuration-files)
  - [How It Works](#how-it-works)
  - [About Rate Limits of Let's Encrypt](#about-rate-limits-of-lets-encrypt)
  - [Credits](#credits)

## Warning

This project is in active development. Use it in production with CAUTION.

## Prerequisite

HTTPS-PORTAL is shipped as a Docker image. To use it, you need a Linux machine
(either local or remote host) which:

* Has 80 and 443 port available and exposed.
* Has [Docker Engine](https://docs.docker.com/engine/installation/) installed.
  In addition, [Docker Compose](https://docs.docker.com/compose/) is highly
  recommended, for it makes your life easier. Examples in our documents are
  mainly in Docker Compose format.
* Has all domains you're going to use in the following examples resolving to
  it.

Though it is good to have, knowledge about Docker is not required to use
HTTPS-PORTAL.

## See It Work

Create a `docker-compose.yml` file with the following content in any directory
of your choice:

```yaml
https-portal:
  image: steveltn/https-portal
  ports:
    - '80:80'
    - '443:443'
  environment:
    DOMAINS: 'example.com'
    # PRODUCTION: 'true'
```

Run `docker-compose up` command in the same directory. A moment later you'll
have a welcome page running in
[https://example.com](https://example.com).

## Quick Start

This is a more real-world example `docker-compose.yml`, create it in another
directory:

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
    # PRODUCTION: 'true'
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

Run `docker-compose up -d` command. A moment later you'll get a WordPress
running on [https://wordpress.example.com](https://wordpress.example.com).

In the example above, only the environment variables under `https-portal`
section are HTTPS-PORTAL specific configurations. This time we added an extra
parameter `-d`, it will tell Docker Compose to run the apps defined in
`docker-compose.yml` in background.

Note: `PRODUCTION` flag is `false` by default, which results in a test
(untrusted) certificate from Let's Encrypt.

## Features

### Automatic Container Discovery

HTTPS-PORTAL is capable of discovering other Docker containers running on the
same host, as long as Docker API socket is accessible within the container.

In order to make it so, launch HTTPS-PORTAL using the following `docker-compose.yml`.

**Notice**: Container discovery doesn't work with compose v2 syntax for now, because of an incompatibility between the
new network interface and docker-gen.

```yaml
https-portal:
  # ...
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

and launch one or more web applications with:

```yaml
a-web-application:
  # ...
  ports:
    - '8080:80'
  environment:
    # tell HTTPS-PORTAL to set up "example.com"
    VIRTUAL_HOST: example.com
```

Note that here is **no need** to link your web service to HTTPS-PORTAL, and you **shouldn't** put `example.com` in environment variable `DOMAINS` of HTTP-PORTAL.

This feature allows you to deploy multiple web applications on the same host
without restarting HTTPS-PORTAL itself or interrupting other application while
adding/removing web applications.

If your web service has more than one port exposed (mind that ports can be exposed in your web service Dockerfile),
use environment variable `VIRTUAL_PORT` to specify which port accepts HTTP request:

```yaml
a-multi-port-web-application:
  # ...
  ports:
    - '8080:80'
    - '2222:22'
  environment:
    VIRTUAL_HOST: example.com
    VIRTUAL_PORT: '8080'
```

Of course container discovery works in combination with ENV specified domains:

```yaml
https-portal:
  # ...
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    DOMAINS: 'example.com -> http://upstream'
```

### Hybrid Setup with Non-Dockerized Apps

Web applications that run directly on host machine instead of in Docker
containers are available at `dockerhost`.

For instance, if an application accepts HTTP requests on port 8080 of the host
machine, you can start HTTPS-PORTAL by:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'example.com -> http://dockerhost:8080'
```

### Multiple Domains

You can specify multiple domains by splitting them with commas:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress, gitlab.example.com
    -> http://gitlab'
```

### Serving Static Sites

Instead of forwarding requests to web applications, HTTPS-PORTAL can also serve
(multiple) static sites directly:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'hexo.example.com, octopress.example.com'
  volumes:
    - /data/https-portal/vhosts:/var/www/vhosts
```

After HTTPS-PORTAL started, it will create corresponding sub-directories for
each virtual host in `/data/https-portal/vhosts` directory on the host machine:

```
/data/https-portal/vhosts
├── hexo.example.com
│  └── index.html
└── octopress.example.com
    └── index.html
```

You can place your own static files in this directory hierarchy, they will not
be overwritten. You need an `index.html` to be served as the homepage.

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

Now your certificates are available in `/data/ssl_certs` of your host.

## Advanced Usage

### Configure Nginx through Environment Variables

There are several additional environment variables that you can use to config Nginx.
They are coressponding to the configuration options that you would normally supply in `nginx.conf`.
The following are the config keys with default values:

```
WORKER_PROCESSES=1
WORKER_CONNECTIONS=1024
KEEPALIVE_TIMEOUT=65
GZIP=on
SERVER_TOKENS=off
SERVER_NAMES_HASH_MAX_SIZE=512
SERVER_NAMES_HASH_BUCKET_SIZE=32        # defaults to 32 or 64 based on your CPU
CLIENT_MAX_BODY_SIZE=1M                 # 0 disables checking request body size
```

### Override Nginx Configuration Files

You can override default nginx settings by providing a config segment of
nginx.conf containing a valid `server` block. The custom nginx configurations
are [ERB](http://www.stuartellis.eu/articles/erb/) templates and will be
rendered before usage.

For instance, to override both HTTPS and HTTP settings for `my.example.com`,
you can launch HTTPS-PORTAL by:

```yaml
https-portal:
  # ...
  volumes:
    - /path/to/http_config:/var/lib/nginx-conf/my.example.com.conf.erb:ro
    - /path/to/https_config:/var/lib/nginx-conf/my.example.com.ssl.conf.erb:ro
```

[This file](https://github.com/SteveLTN/https-portal/blob/master/fs_overlay/var/lib/nginx-conf/default.conf.erb) and [this file](https://github.com/SteveLTN/https-portal/blob/master/fs_overlay/var/lib/nginx-conf/default.ssl.conf.erb) are the default configuration files used by HTTPS-PORTAL.
You can probably start by copying these files and make modifications on them.

Another example can be found [here](/examples/custom_config).

If you want to make an Nginx configuration that will be used by all sites, you can overwrite `/var/lib/nginx-conf/default.conf.erb` or `/var/lib/nginx-conf/default.ssl.conf.erb`. These two files will be propagated to each site if the site-specific configuration files are not provided.

## How It Works

It:

* obtains an SSL certificate for each of your subdomains from
  [Let's Encrypt](https://letsencrypt.org).
* configures Nginx to use HTTPS (and force HTTPS by redirecting HTTP to HTTPS)
* sets up a cron job that checks your certificates every week, and renew them.
  if they expire in 30 days.

## About Rate Limits of Let's Encrypt

Let's Encrypt is in public beta at the moment. According to
[this](https://community.letsencrypt.org/t/public-beta-rate-limits/4772) and
[this discussion](https://community.letsencrypt.org/t/public-beta-rate-limits/4772/42),
the rate limits are

* 10 registrations per IP per 3 hours.
* 5 certificates per domain (not sub-domain) per 7 days.

The former is not usually a problem, however the latter could be, if you want
to apply certificates for multiple sub-domains on a single domain. Let's
Encrypt does support SAN certificates, however it requires careful planning
and is hard to automate. So in HTTPS-PORTAL we only deal with CN certificates.

HTTPS-PORTAL stores your certificates in a data volume and will not re-sign
certificates until 30 days before expiration if a valid certificate is found
(you can force renew certificates by using `FORCE_RENEW: 'true'` environment
variable).  However if you play around with the image a lot, you can hit the
limit. That's why `PRODUCTION` flag is off by default, and thus we use the
Let's Encrypt staging server. When you made your experiments and feel
everything is good, you can switch to production mode with `PRODUCTION:
'true'`.

According to Let's Encrypt, the restrictions will be loosen as the beta goes.

## Credits

* [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler.
* [docker-gen](https://github.com/jwilder/docker-gen) by Jason Wilder.
* [s6-overlay](https://github.com/just-containers/s6-overlay).
