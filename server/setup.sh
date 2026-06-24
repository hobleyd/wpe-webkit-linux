#!/bin/bash
# Run once on the server at wpe-webkit-linux.sharpblue.com.au to initialise
# the APT repository.  Requires: nginx, reprepro, gpg.
#
# Usage: sudo bash setup.sh

set -euo pipefail

REPO_ROOT=/srv/apt
WEBROOT=/var/www/wpe-webkit-linux
DISTRO=noble
GPG_KEY_ID="${1:-}"   # pass your GPG key ID as $1, or set GPG_KEY_ID

# ── Dependencies ──────────────────────────────────────────────────────────────
apt-get install -y nginx reprepro gpg

# ── Repo directory structure ──────────────────────────────────────────────────
mkdir -p "${REPO_ROOT}/conf" "${WEBROOT}"

# ── reprepro distributions config ─────────────────────────────────────────────
cat > "${REPO_ROOT}/conf/distributions" <<EOF
Origin: wpe-webkit-linux.sharpblue.com.au
Label: WPE WebKit for Ubuntu Noble
Codename: ${DISTRO}
Architectures: amd64
Components: main
Description: WPEWebKit 1.0 ABI built against Ubuntu 24.04 (glibc 2.39)
SignWith: ${GPG_KEY_ID}
EOF

# ── nginx site ─────────────────────────────────────────────────────────────────
cat > /etc/nginx/sites-available/wpe-webkit-linux <<'NGINX'
server {
    listen 80;
    server_name wpe-webkit-linux.sharpblue.com.au;

    root /var/www/wpe-webkit-linux;
    autoindex on;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/wpe-webkit-linux \
       /etc/nginx/sites-enabled/wpe-webkit-linux
nginx -t && systemctl reload nginx

# ── Symlink repo into webroot ──────────────────────────────────────────────────
ln -sfn "${REPO_ROOT}" "${WEBROOT}/apt"

# ── Export GPG public key for consumers ───────────────────────────────────────
gpg --export --armor "${GPG_KEY_ID}" \
  > "${WEBROOT}/wpe-webkit-linux.gpg"

echo ""
echo "Repo initialised at ${REPO_ROOT}"
echo "Serving at http://wpe-webkit-linux.sharpblue.com.au/apt"
echo "Public key at http://wpe-webkit-linux.sharpblue.com.au/wpe-webkit-linux.gpg"
echo ""
echo "Add the following GitHub Actions secrets:"
echo "  REPO_SSH_KEY  — private SSH key for the deploy user"
echo "  REPO_USER     — SSH username on this server"
