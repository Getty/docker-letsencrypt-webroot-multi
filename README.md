# Let’s Encrypt (webroot) in a Docker for multiply hosts

![Letsencrypt Logo](https://letsencrypt.org/images/letsencrypt-logo-horizontal.svg)

Letsencrypt cert auto getting and renewal script based on original [certbot/certbot](https://hub.docker.com/r/certbot/certbot/) base image. Inspired by [kvaps/docker-letsencrypt-webroot](https://github.com/kvaps/docker-letsencrypt-webroot) and its [forks](https://github.com/kvaps/docker-letsencrypt-webroot/network).

  - [GitHub](https://github.com/Getty/docker-letsencrypt-webroot)
  - [DockerHub](https://hub.docker.com/r/raudssus/letsencrypt-webroot-multi/)


## Usage

* First, you need to set up your web server so that it gave the contents of the `/.well-known/acme-challenge` directory properly. 
  Example, for nginx add location for your server:
```nginx
  location /.well-known/acme-challenge {
    default_type "text/plain";
    root         /tmp/letsencrypt;
  }
```


* Then run your web server image with letsencrypt-webroot-multi connected volumes:
```bash
  -v /var/www/letsencrypt:/tmp/letsencrypt
```


* Write a `/etc/letsencrypt/certs.txt` file for configuration:
```text
  email@example.com example.com www.example.com
  email@universe.org universe.org
```


* Run letsencrypt-webroot-multi image:
```bash
  docker run \
    --restart always \
    --name letsencrypt \
    -v /data/letsencrypt:/etc/letsencrypt \
    -v /data/letsencrypt-www:/tmp/letsencrypt \
    raudssus/letsencrypt-webroot-multi
```


* Configure your app to use certificates in the following path:

  * **Private key**: `/etc/letsencrypt/live/example.com/privkey.pem`
  * **Certificate**: `/etc/letsencrypt/live/example.com/cert.pem`
  * **Intermediates**: `/etc/letsencrypt/live/example.com/chain.pem`
  * **Certificate + intermediates**: `/etc/letsencrypt/live/example.com/fullchain.pem`

  * **Private key**: `/etc/letsencrypt/live/universe.org/privkey.pem`
  * **Certificate**: `/etc/letsencrypt/live/universe.org/cert.pem`
  * **Intermediates**: `/etc/letsencrypt/live/universe.org/chain.pem`
  * **Certificate + intermediates**: `/etc/letsencrypt/live/universe.org/fullchain.pem`

**NOTE**: You should connect `/etc/letsencrypt` directory fully, because if you connect just `/etc/letsencrypt/live`, then symlinks to your certificates inside it will not work!


## Docker-compose

This is example of letsencrypt-webroot-multi `docker-compose.yml` with nginx configuration:

```yaml
nginx:
  restart: always
  image: nginx
  hostname: example.com
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - ./nginx:/etc/nginx:ro
    - ./letsencrypt/conf:/etc/letsencrypt
    - ./letsencrypt/html:/tmp/letsencrypt
  ports:
    - 80:80
    - 443:443

letsencrypt:
  image: raudssus/letsencrypt-webroot-multi
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - /var/run/docker.sock:/var/run/docker.sock
    - ./letsencrypt/conf:/etc/letsencrypt
    - ./letsencrypt/html:/tmp/letsencrypt
```


## Environment variables

* **EXP_LIMIT**: The number of days before expiration of the certificate before request another one. Defaults to 30.
* **CHOWN**: Owner for certs. Defaults to `root:root`.
* **CHMOD**: Permissions for certs. Defaults to `644`.
* **CHMOD_DIRECTORY**: Permissions for cert directories. Defaults to `755`.
* **CERTBOT_ADDITIONAL**: Additional parameter for the `certonly` call to `certbot`
* **WAITING_TIME**: Waiting this many hours between checks of `certs.txt` and renewal check of certs. Defaults to 6.
