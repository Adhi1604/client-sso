#!/bin/bash

# Step 1: Install Kerberos packages without GUI prompts
echo ":package: Installing Kerberos packages silently..."
echo "krb5-config krb5-config/default_realm string REFEX.GROUP" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y krb5-user libpam-krb5 || {
  echo ":x: Package installation failed."
  exit 1
}

# Step 2: Configure /etc/krb5.conf
echo ":hammer_and_wrench: Configuring /etc/krb5.conf..."
sudo bash -c 'cat > /etc/krb5.conf' <<EOF
[libdefaults]
    default_realm = REFEX.GROUP
    dns_lookup_realm = true
    dns_lookup_kdc = true
    rdns = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    kdc_timesync = 1
    ccache_type = 4
    proxiable = true

[realms]
    REFEX.GROUP = {
        kdc = akkuv2.refex.group
        admin_server = akkuv2.refex.group
    }

[domain_realm]
    .refex.group = REFEX.GROUP
    refex.group = REFEX.GROUP
EOF

echo ":white_check_mark: Kerberos config updated for REFEX.GROUP."

# Step 3: Get Akku username
echo ""
echo ":closed_lock_with_key: Please enter your REFEX username (without @REFEX.GROUP):"
read KRB_USERNAME
KRB_REALM="REFEX.GROUP"
KRB_USER="$KRB_USERNAME@$KRB_REALM"

# Step 4: Authenticate using kinit
echo ":hourglass_flowing_sand: Authenticating using kinit for $KRB_USER..."
kinit "$KRB_USER" || {
  echo ":x: Authentication failed. Check your realm, username, or password."
  exit 1
}

echo ":white_check_mark: Kerberos ticket obtained successfully!"
klist

# Step 5: Create Linux user using extracted KRB_USERNAME
NEW_USER="$KRB_USERNAME"
echo ""
echo ":bust_in_silhouette: Using '$NEW_USER' as Linux username..."

if id "$NEW_USER" &>/dev/null; then
  echo ":information_source: User '$NEW_USER' already exists. Skipping creation."
else
  echo ":adult: Creating user '$NEW_USER'..."
  sudo adduser --disabled-password --gecos "" --force-badname "$NEW_USER" || {
    echo ":x: Failed to create user '$NEW_USER'."
    exit 1
  }

  sudo usermod -aG sudo "$NEW_USER" || {
    echo ":warning: User created, but failed to add '$NEW_USER' to sudo group."
    exit 1
  }

  echo ":white_check_mark: User '$NEW_USER' created and added to sudo group."
fi

# Step 6: Add Chrome Kerberos config
POLICY_DIR="/etc/opt/chrome/policies/managed"
POLICY_FILE="$POLICY_DIR/kerberos_policy.json"
JSON_CONTENT='{
  "AuthServerAllowlist": "*.akku.work",
  "AuthNegotiateDelegateAllowlist": "*.akku.work",
  "EnableAuthNegotiatePort": true,
  "DisableAuthNegotiateCnameLookup": false
}'

if [ ! -d "$POLICY_DIR" ]; then
  echo "Creating directory $POLICY_DIR"
  sudo mkdir -p "$POLICY_DIR"
fi

echo "Writing Kerberos policy to $POLICY_FILE"
echo "$JSON_CONTENT" | sudo tee "$POLICY_FILE" > /dev/null

echo "✅ Done. Chrome Kerberos policy has been set."
