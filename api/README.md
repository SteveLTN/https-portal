# dappnode-portal-api

## Build docker image

```bash
docker build -t https-portal-dappnode-api .
```

Run the server using docker

```bash
docker run -p 5000:5000 -e "PUBLIC_DOMAIN=your.domain" -v "portal-domains:/usr/data/" https-portal-dappnode-api
```
