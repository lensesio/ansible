#!/usr/bin/env bash

# Copyright 2015, Landoop LTD, Marios Andreopoulos.
# BSD license, check repository's top directory.

EXTERNALIP="$1"
declare -a WITHOUTCERT
declare -a WITHOUTCERTCONF
CUR=0

if [ -z "$1" ]; then
    echo "No external IP provided."
    exit 1
fi

# For each nginx configuration file.
for i in /etc/nginx/conf.d/*.conf; do
    # Find server's SSL key
    KEY="$(grep -m 1 ssl_certificate_key "$i" | sed -r 's|.*(/var.*)[:white:]*;.*|\1|')"

    # If key does not exist
    if [ ! -f $KEY ]; then
        # Find server name
        SERVER="$(echo $KEY | cut -d / -f 6)"

        # Check if server has DNS records
        if host -4 -t A "$SERVER" > /dev/null; then
            ARECORD="$(host -4 -t A "$SERVER" | cut -d " " -f 4)"

            # Check if our external IP matches the DNS records for this server
            if [ "$ARECORD" == "$EXTERNALIP" ]; then
                # Great, we can request a certificate
                WITHOUTCERT[$CUR]="$SERVER"
                WITHOUTCERTCONF[$CUR]="$i"
                let CUR++
            else
                echo "Server $SERVER (file $i) does not have correct DNS A records. Record $ARECORD instead of asked $EXTERNALIP."
                exit 1
            fi
        else
            echo "Server $SERVER (file $i) does not have DNS A records."
        fi
    fi
done

# Only do the procedure if we have SSL certs to request:
if (( $CUR > 0 )); then

    # Alter nginx configuration so it can start:
    for (( i = 0; i < $CUR; i++ )); do
        # Disable current conf as it is unusable due to missing SSL key (nginx won't start)
        mv "${WITHOUTCERTCONF[$i]}" "${WITHOUTCERTCONF[$i]}.disabled"
        # Create a temporar nginx configuration.
        echo -e "server {\n listen 80;\n server_name ${WITHOUTCERT[$i]};\n include includes/lets-encrypt.conf; \n}" > \
            "${WITHOUTCERTCONF[$i]}"
    done

    # Start nginx, request certificates, restore configuration files:
    systemctl restart nginx || { echo "Could not start nginx with temporary configuration."; exit 1; }
    for (( i = 0; i < $CUR; i++ )); do
        /usr/local/bin/acmetool want ${WITHOUTCERT[$i]} || { echo "Acmetool failed for server ${WITHOUTCERT[$i]}"; exit 1; }
        mv "${WITHOUTCERTCONF[$i]}.disabled" "${WITHOUTCERTCONF[$i]}"
    done

    systemctl restart nginx || { echo "Could not restart nginx with ansible provided configuration."; exit 1; }

fi
