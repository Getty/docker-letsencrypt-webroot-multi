#!/bin/bash

set +x

webroot_path=${WEBROOT_PATH:-/tmp/letsencrypt}
exp_limit="${EXP_LIMIT:-30}"
waiting_time="${WAITING_TIME:-6}"

additional="$CERTBOT_ADDITIONAL"

le_fixpermissions () {
  echo "[INFO] Fixing permissions"
  chown -R ${CHOWN:-root:root} /etc/letsencrypt
  find /etc/letsencrypt -type d -exec chmod ${CHMOD_DIRECTORY:-755} {} \;
  find /etc/letsencrypt -type f -exec chmod ${CHMOD:-644} {} \;
}

le_renew () {
  renew_email=$1
  renew_domains=${@:2}
  cert_dir="/etc/letsencrypt/live/$2"
  certbot_domains=""
  for domain in ${renew_domains}; do
    certbot_domains="${certbot_domains} -d $domain"
  done
  if [ -f "$cert_dir/.self-signed" ]; then
    rm "$cert_dir"
  fi
  certbot certonly --webroot --agree-tos --renew-by-default --text $additional --email $renew_email -w $webroot_path $certbot_domains
  if [ ! -f "$cert_dir" ]; then
    ln -s "$cert_dir-self-signed" "$cert_dir"
  fi
  le_fixpermissions
}

le_check () {
  cert_file="/etc/letsencrypt/live/$2/fullchain.pem"

  if [ -f $cert_file ]; then

    exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
    datenow=$(date -d "now" +%s)
    days_exp=$[ ( $exp - $datenow ) / 86400 ]

    echo "Checking expiration date for $2..."

    if [ "$days_exp" -gt "$exp_limit" ]; then
        echo "The certificate is up to date, no need for renewal ($days_exp days left)."
    else
        echo "The certificate for $2 is about to expire soon. Starting webroot renewal script..."
        le_renew $@
        echo "Renewal process finished for domain $2"
    fi

    echo "Checking domains for $2..."

    domains=($(openssl x509  -in $cert_file -text -noout | grep -oP '(?<=DNS:)[^,]*'))
    new_domains=($(
      for domain in ${@:2}; do
        [[ " ${domains[@]} " =~ " ${domain} " ]] || echo $domain
      done
    ))

    if [ -z "$new_domains" ]; then
      echo "The certificate have no changes, no need for renewal"
    else
      echo "The list of domains for $2 certificate has been changed. Starting webroot renewal script..."
      le_renew $@
      echo "Renewal process finished for domain $2"
    fi

  else

    echo "[INFO] certificate file not found for domain $2. Generating temporary self-signed..."
    install -d "/etc/letsencrypt/live/$2-self-signed"
    touch "/etc/letsencrypt/live/$2-self-signed/.self-signed"
    openssl req -x509 -newkey rsa:4096 -sha256 -nodes -subj "/CN=$2" -days 1 \
      -keyout "/etc/letsencrypt/live/$2-self-signed/privkey.pem" -out "/etc/letsencrypt/live/$2-self-signed/fullchain.pem"
    ln -s "/etc/letsencrypt/live/$2-self-signed" "/etc/letsencrypt/live/$2"

  fi
}

while true; do

  while IFS='' read -r line || [[ -n "$line" ]]; do
    le_check $line
  done < "/etc/letsencrypt/certs.txt"

  sleep $(( $waiting_time * 60 * 60 ))

done
