# nginx-acme

Nginx container with HTTPS shipped.

## Introduction

This project is in a very early stage. Currently it comes with my test domain hard-coded. But feel free to do experiments with it.

It is currently using the staging Let's Encrypt ACME server, by default the certificate is not trusted.

This project includes a copy of the fantastic project [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler. Thank you Daniel!

## How to run

1. Create a machine with docker daemon installed

1. Configure your DNS server

1. Build Docker image

	`docker build --tag steveltn/nginx-acme ./`

1. Run your container

	`docker run -it --rm -p 80:80 -p 443:443 steveltn/nginx-acme`

1. Visit your HTTPS site!
