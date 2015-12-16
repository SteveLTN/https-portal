# nginx-acme

Nginx container with HTTPS shipped.

## Warning

This project is in a very early stage. Do NOT use it in production!

## Introduction

Nginx-acme is a Docker container with Nginx installed, together with a ACME client to obtain free SSL certificates from [Let's Encrypt](https://letsencrypt.org) automatically. 

It:

* obtains an SSL certificate for each of your domains from [Let's Encrypt](https://letsencrypt.org)
* configures Nginx to forward HTTPS requests
* sets up cron jobs to automatically renew your certificates every month

This project includes a copy of the fantastic project [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler. Thank you Daniel!

## Usage

1. Create a Linux machine with Docker daemon installed

1. Configure your DNS server

1. Run the container. I recommend running it by using [docker-compose](https://docs.docker.com/compose/).

	A Sample `docker-compose.yml` looks like:
	
```
nginx-acme:
  image: steveltn/nginx-acme
  ports:
    - 80:80
    - 443:443
  environment:
    # Using staging server by default, for there is a rate limit on production
    # Uncomment to use Let's Encrypt production server
    # - "PRODUCTION=true"
    - "FORWARD_NGINX-ACME.STEVELTN.ME=http://localhost:8000"
  container_name: nginx-acme
		
```

And now you can visit your HTTPS site!