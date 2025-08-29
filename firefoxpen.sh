#!/bin/bash

CERT=~/caido.crt           # Path to your proxy CA cert
PROXY_HOST="127.0.0.1"     # Proxy IP
PROXY_PORT="8080"          # Proxy Port

# Find the default Firefox profile
PROFILE=$(awk -F= '/Default=1/{getline; print $2}' ~/.mozilla/firefox/profiles.ini)
PROFILE_DIR="$HOME/.mozilla/firefox/$PROFILE"
DB="sql:$PROFILE_DIR"

if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "[-] Could not find Firefox profile directory"
    exit 1
fi

enable_mode() {
    echo "[+] Enabling pentest mode for profile: $PROFILE"

    # Install CA cert
    certutil -A -n "Pentest Root CA" -t "C,," -i "$CERT" -d "$DB" 2>/dev/null

    # Configure proxy in user.js
    cat >> "$PROFILE_DIR/user.js" <<EOF

// Added by pentest script
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "$PROXY_HOST");
user_pref("network.proxy.http_port", $PROXY_PORT);
user_pref("network.proxy.ssl", "$PROXY_HOST");
user_pref("network.proxy.ssl_port", $PROXY_PORT);
user_pref("network.proxy.ftp", "$PROXY_HOST");
user_pref("network.proxy.ftp_port", $PROXY_PORT);
user_pref("network.proxy.socks", "$PROXY_HOST");
user_pref("network.proxy.socks_port", $PROXY_PORT);
EOF

    echo "[+] Proxy set to $PROXY_HOST:$PROXY_PORT"
    echo "[+] CA cert installed"
}

disable_mode() {
    echo "[+] Disabling pentest mode for profile: $PROFILE"

    # Remove cert
    certutil -D -n "Pentest Root CA" -d "$DB" 2>/dev/null

    # Reset proxy by rewriting user.js without the custom lines
    sed -i '/Added by pentest script/,$d' "$PROFILE_DIR/user.js"

    echo "[+] Proxy and CA cert removed"
}

case "$1" in
    --enable)
        enable_mode
        ;;
    --disable)
        disable_mode
        ;;
    *)
        echo "Usage: $0 --enable | --disable"
        ;;
esac
