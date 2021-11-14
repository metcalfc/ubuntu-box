#!/bin/sh -eux

gitpod='
This system is built by Gitpod using templates derived from the Bento project by Chef Software.
'

if [ -d /etc/update-motd.d ]; then
    MOTD_CONFIG='/etc/update-motd.d/99-gitpod'

    cat >> "$MOTD_CONFIG" <<GITPOD
#!/bin/sh

cat <<'EOF'
$gitpod
EOF
GITPOD

    chmod 0755 "$MOTD_CONFIG"
else
    echo "$gitpod" >> /etc/motd
fi
