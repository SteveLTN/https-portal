# HTTPS-PORTAL

HTTPS-PORTAL is a fully automated HTTPS server powered by
[Nginx](http://nginx.org), [Let's Encrypt](https://letsencrypt.org) and
[Docker](https://www.docker.com). By using it, you can run any existing web
application over HTTPS, with only one extra line of configuration.

The SSL certificates are obtained, and renewed from Let's Encrypt
automatically.

Docker Hub page:
[https://hub.docker.com/r/steveltn/https-portal/](https://hub.docker.com/r/steveltn/https-portal/)

## Table of Contents

- [HTTPS-PORTAL](#https-portal)
  - [Prerequisite](#prerequisite)
  - [See It Work](#see-it-work)
  - [Quick Start](#quick-start)
  - [Features](#features)
    - [Test Locally](#test-locally)
    - [Redirections](#redirections)
    - [Automatic Container Discovery](#automatic-container-discovery)
    - [Hybrid Setup with Non-Dockerized Apps](#hybrid-setup-with-non-dockerized-apps)
    - [Multiple Domains](#multiple-domains)
    - [Serving Static Sites](#serving-static-sites)
    - [Share Certificates with Other Apps](#share-certificates-with-other-apps)
    - [HTTP Basic Auth](#http-basic-auth)
    - [Access Restriction](#access-restriction)
  - [Advanced Usage](#advanced-usage)
    - [Configure Nginx through Environment Variables](#configure-nginx-through-environment-variables)
    - [Override Nginx Configuration Files](#override-nginx-configuration-files)
  - [How It Works](#how-it-works)
  - [About Rate Limits of Let's Encrypt](#about-rate-limits-of-lets-encrypt)
  - [Troubleshooting](#troubleshooting)
  - [Credits](#credits)

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
  image: steveltn/https-portal:1
  ports:
    - '80:80'
    - '443:443'
  environment:
    DOMAINS: 'example.com'
    # STAGE: 'production'
```

Run the `docker-compose up` command in the same directory. A moment later you'll
have a welcome page running in
[https://example.com](https://example.com).

## Quick Start

Here is a more real-world example: Create the file `docker-compose.yml` in another
directory:

```yaml
https-portal:
  image: steveltn/https-portal:1
  ports:
    - '80:80'
    - '443:443'
  links:
    - wordpress
  restart: always
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress:80'
    # STAGE: 'production'
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

Run the `docker-compose up -d` command. A moment later you'll get a WordPress
running on [https://wordpress.example.com](https://wordpress.example.com).

In the example above, only the environment variables under the `https-portal`
section are HTTPS-PORTAL specific configurations. This time we added an extra
parameter `-d`, which will tell Docker Compose to run the apps defined in
`docker-compose.yml` in the background.

Note: `STAGE` is `staging` by default, which results in a test
(untrusted) certificate from Let's Encrypt.

## Features

### Test Locally

You can test HTTPS-PORTAL with your application stack locally.

```yaml
https-portal:
  # ...
  environment:
    STAGE: local
    DOMAINS: 'example.com'
```

By doing this, HTTPS-PORTAL will create a self-signed certificate.
This certificate is not likely to be trusted by your browser, but you can
use it to test your docker-compose file. Make sure it works with your application
stack.

Note that HTTPS-PORTAL only listens to `example.com`, as you specified in the compose file.
In order to make HTTPS-PORTAL respond to your connection, you need to either:

* modify your `hosts` file to have `example.com` resolving to your docker host,

or

* set up DNSMasq on your computer/router. This method provides more flexibility.

Once you are done testing, you can deploy your application stack to the server.

### Redirections

HTTPS-PORTAL support quick setup for redirections. It is deliberately made to
support https targets only because otherwise it'd be against the idea of this project.

```yaml
https-portal:
  # ...
  environment:
    STAGE: local
    DOMAINS: 'example.com => https://target.example.com/foo/bar' # Notice it's "=>" instead of the normal "->"
```

### Automatic Container Discovery

**WARNING: WE STRONGLY RECOMMEND AGAINST USING THIS FEATURE UNLESS ABSOLUTELY NECESSARY** as exposing Docker socket to a container (even with `:ro`) essentially gives the container root access to your host OS. If you insist, verify the source code carefully. [Read more](https://dev.to/petermbenjamin/docker-security-best-practices-45ih)

HTTPS-PORTAL is capable of discovering other Docker containers running on the
same host, as long as the Docker API socket is accessible within the container.

In order to make it so, launch HTTPS-PORTAL using the following `docker-compose.yml`.

```yaml
version: '2'

services:
  https-portal:
    # ...
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro # DANGEROUS, see the warning above
```

and launch one or more web applications with:

```yaml
version: '2'

services:
  a-web-application:
    # ...
    environment:
      # tell HTTPS-PORTAL to set up "example.com"
      VIRTUAL_HOST: example.com
```

**Caveat**: Your web application must be created in the same network as HTTPS-PORTAL.

Note that here is **no need** to link your web service to HTTPS-PORTAL, and you **shouldn't** put `example.com` in environment variable `DOMAINS` of HTTP-PORTAL.

This feature allows you to deploy multiple web applications on the same host
without restarting HTTPS-PORTAL itself or interrupting any other application while
adding/removing web applications.

If your web service has more than one port exposed (mind that ports can be exposed in your web service Dockerfile),
use the environment variable `VIRTUAL_PORT` to specify which port accepts HTTP requests:

```yaml
a-multi-port-web-application:
  # ...
  expose:
    - '80'
    - '8080'
  environment:
    VIRTUAL_HOST: example.com
    VIRTUAL_PORT: '8080'
```

Of course container discovery works in combination with ENV specified domains:

```yaml
https-portal:
  # ...
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro # DANGEROUS, see the warning above
  environment:
    DOMAINS: 'example.com -> http://upstream'
```

### Hybrid Setup with Non-Dockerized Apps

Web applications that run directly on the host machine instead of in Docker
containers are available at `dockerhost`.

For instance, if an application accepts HTTP requests on port 8080 of the host
machine, you can start HTTPS-PORTAL by:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'example.com -> http://dockerhost:8080'
```

#### Firewall settings ####

If you use a firewall like [ufw](https://help.ubuntu.com/community/UFW), you
might need to allow communication from the container to your docker host machine.
You can check if ufw is active by executing `ufw status`.

If the command returns `active`, add the ufw rule to allow communication on port 8080 from HTTPS-PORTAL's container IP to the docker host IP on the port where the web application is reachable:

```
DOCKER_HOST_IP=`docker network inspect code_default --format='{{ .IPAM.Config}}' |awk '{print $2}'` # Assumes that the network is named code_default
HTTPS_PORTAL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' code_https-portal_1` # Assumes that the container has the name code_https-portal_1
ufw allow from $HTTPS_PORTAL_IP to $DOCKER_HOST_IP port 8080
```

### Multiple Domains

You can specify multiple domains by splitting them with commas:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress:80, gitlab.example.com
    -> http://gitlab'
```

You can also specify the stage (`local`, `staging`, or `production`) for each individual site, note that stages of individual sites overrides the global stage:

```yaml
DOMAINS: 'wordpress.example.com -> http://wordpress #local, gitlab.example.com #production'
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

After HTTPS-PORTAL is started, it will create corresponding sub-directories for
each virtual host in the `/data/https-portal/vhosts` directory on the host machine:

```yaml
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

Now your certificates are available in `/data/ssl_certs` on your host.

### HTTP Basic Auth

You can set up an HTTP Basic Auth easily. It is useful when you put the website
online but don't want to open it to public until ready.

In your docker-compose file:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'username:password@example.com -> <upstream>'
```

### Access Restriction

**Notice: Access Restriction might not work as intended with Docker for Mac and Docker for Windows. In those systems, Docker essentially runs in VMs, so the requesting IP would be the IP of the proxy service.**

You can enable IP access restrictions to protect your website. Specify global restrictions with the environment variable `ACCESS_RESTRICTION`. In addition each website can have individual restrictions.

Example with global restriction:

```yaml
https-portal:
  # ...
  environment:
    ACCESS_RESTRICTION: "1.2.3.4/24 4.3.2.1"
```

Example with individual restrictions:

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: "[1.2.3.4/24] a.example.com -> <upstream> , [1.2.3.4/24 4.3.2.1] b.example.com"
```

Example for auto discovery:

```yaml
https-portal:
  # ...
my_app:
  image: ...
  environment:
    VIRTUAL_HOST: "[1.2.3.4] example.com"
```

For valid IP values see [Nginx allow](http://nginx.org/en/docs/http/ngx_http_access_module.html#allow)

## Advanced Usage

### Configure Nginx through Environment Variables

In case you need to change Nginx's default parameters, 
there are several additional environment variables that you can use to config Nginx.
They correspond to the configuration options that you would normally put in `nginx.conf`.
The following are the available params with their default values:

```
WORKER_PROCESSES=1
WORKER_CONNECTIONS=1024
KEEPALIVE_TIMEOUT=65
GZIP=on
SERVER_TOKENS=off
SERVER_NAMES_HASH_MAX_SIZE=512
SERVER_NAMES_HASH_BUCKET_SIZE=32        # defaults to 32 or 64 based on your CPU
CLIENT_MAX_BODY_SIZE=1M                 # 0 disables checking request body size
PROXY_BUFFERS="8 4k"                    # Either 4k or 8k depending on the platform
PROXY_BUFFER_SIZE="4k"                  # Either 4k or 8k depending on the platform
RESOLVER="Your custom solver string"
PROXY_CONNECT_TIMEOUT=60;
PROXY_SEND_TIMEOUT=60;
PROXY_READ_TIMEOUT=60;
ACCESS_LOG=off;
```

You can also add

```
WEBSOCKET=true
```

to make HTTPS-PORTAL proxy WEBSOCKET connections.

To avoid nginx DNS caching, activate dynamic upstream

```
RESOLVER="127.0.0.11 ipv6=off valid=30s"
DYNAMIC_UPSTREAM=true
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
You can probably start by copying these files and make modifications to them.

Another example can be found [here](/examples/custom_config).

If you want to make an Nginx configuration that will be used by all sites, you can overwrite `/var/lib/nginx-conf/default.conf.erb` or `/var/lib/nginx-conf/default.ssl.conf.erb`. These two files will be propagated to each site if the site-specific configuration files are not provided.

### Manually Set RSA Private Key Length

By default, HTTPS-PORTAL generate `2048` bits long RSA private key.  
However, you can manually set RSA private key length (`numbits` of `openssl genrsa` command) through `NUMBITS` environment variable.

```yaml
https-portal:
  # ...
  environment:
    NUMBITS: '4096'
```

## How It Works

It:

* obtains an SSL certificate for each of your subdomains from
  [Let's Encrypt](https://letsencrypt.org).
* configures Nginx to use HTTPS (and force HTTPS by redirecting HTTP to HTTPS)
* sets up a cron job that checks your certificates every week, and renew them.
  if they expire in 30 days.

## About Rate Limits of Let's Encrypt

Let's Encrypt's service is rate limited to ensure fair usage. Please familiarize
yourself with [the various rate
limits](https://letsencrypt.org/docs/rate-limits/). This documentation page is
the authoritative source for the current rate limit values.

For most people the most important rate limits are:

* 5 failed validation attempts per hour
* 50 certificates per registered domain per week

If you want to use HTTPS for multiple sub-domains with a single certificate
Let's Encrypt supports putting up to 100 domains in one certificate, however it
can require careful planning and is hard to automate. So in HTTPS-PORTAL we only
deal with single domain name certificates.

HTTPS-PORTAL stores your certificates in a data volume and will not re-sign
certificates until 30 days before expiration if a valid certificate is found
(you can force renew certificates by using `FORCE_RENEW: 'true'` environment
variable).  However if you play around with the image a lot, you can hit the
limit. That's why `STAGE` is `staging` by default, and thus we use the
Let's Encrypt staging server. When you have finished your experiments and feel
everything is good, you can switch to production mode with `STAGE:
'production'`.

## Troubleshooting

If you find your certificates are not chained correctly, please run the container
again with the follow setting once:

```yaml
https-portal:
  # ...
  environment:
    # ...
    FORCE_RENEW: 'true' # <-- here
```

This is because with ACME v2 returns the full chain instead of a partial chain 
with ACME v1. If you have old certificates stored, HTTPS-PORTAl may not be able 
to handle the case correctly. If you run into this issue, just `FORCE_RENEW` to 
obtain a new set of certificates.

## Credits

* [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler.
* [docker-gen](https://github.com/jwilder/docker-gen) by Jason Wilder.
* [s6-overlay](https://github.com/just-containers/s6-overlay).
