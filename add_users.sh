  GNU nano 8.4                        add_users.sh
#!/bin/bash
CSV_FILE="users.csv"
CONF_FILE="/etc/asterisk/pjsip.conf"

while IFS=',' read -r USERNAME PASSWORD; do
  echo "Ajout de l'utilisateur $USERNAME..."
  cat <<EOF >> $CONF_FILE

[$USERNAME]
type=endpoint
context=internal
disallow=all
allow=ulaw,alaw
auth=$USERNAME
aors=$USERNAME

[$USERNAME]
type=auth
auth_type=userpass
password=$PASSWORD
username=$USERNAME

[$USERNAME]
type=aor
max_contacts=1
EOF
done < "$CSV_FILE"

asterisk -rx "core reload"
echo "Terminé. Configuration Asterisk rechargée."
