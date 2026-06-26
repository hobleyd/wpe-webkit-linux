# wpe-webkit-linux — Claude Code Guide

## Purpose

Builds WPEWebKit 2.42.x (last stable series with the `wpewebkit-1.0` pkg-config ABI)
on Ubuntu 24.04 (Noble) and publishes `.deb` packages to an APT repository hosted on
GitHub Pages at `hobleyd.github.io/wpe-webkit-linux` (custom domain
`wpe-webkit-linux.sharpblue.com.au` pending DNS fix — CNAME target needs trailing dot).

This exists because:
- `flutter_inappwebview_linux 0.1.0-beta.1` requires `wpewebkit-1.0` (via pkg-config)
- Ubuntu 24.04 dropped WPE WebKit from its repos
- Debian Sid's `libwpewebkit-2.0-dev` uses a different ABI **and** is compiled
  against glibc 2.42, incompatible with Ubuntu 24.04's glibc 2.39

## Critical build flag

`-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2` **must** be passed to cmake.

Ubuntu 24.04's GCC defaults to `FORTIFY_SOURCE=3`, which introduces glibc 2.42
symbol dependencies (`__inet_pton_chk`, `GLIBC_ABI_DT_X86_64_PLT`).
Overriding to `=2` keeps all symbols within glibc 2.39.

## WPEWebKit version

Target: **2.36.x** (the latest 2.36.y patch release, currently 2.36.8).
- The `wpewebkit-1.0` pkg-config ABI (`libWPEWebKit-1.0.so`) is present in ≤ 2.36.
- **2.38+ switched to `wpe-webkit-2.0`** (different pkg-config name, different SONAME:
  `libWPEWebKit-2.0.so`). This was confirmed empirically: 2.42.5 installs
  `wpe-webkit-2.0.pc`, not `wpewebkit-1.0.pc`.
- Do not update past 2.36.x — `flutter_inappwebview_linux` cmake checks for
  `wpewebkit-1.0` specifically and will fail if it only finds `wpe-webkit-2.0`.

## APT repository

Hosted on the `gh-pages` branch, served via GitHub Pages.

URL: `https://hobleyd.github.io/wpe-webkit-linux/apt`
Codename: `noble`
Component: `main`
GPG key: `https://hobleyd.github.io/wpe-webkit-linux/wpe-webkit-linux.gpg`

The custom domain is configured via `CNAME` on the `gh-pages` branch and a CNAME
DNS record pointing `wpe-webkit-linux.sharpblue.com.au` → `hobleyd.github.io`.

## GitHub Actions secrets required

| Secret | Description |
|--------|-------------|
| `GPG_PRIVATE_KEY` | ASCII-armored GPG private key (**no passphrase** — see below) |
| `GPG_KEY_ID` | Long key ID or fingerprint (e.g. `ABCD1234...`) used for `SignWith:` |

### Generating the signing key (one time)

```bash
# Generate a passphrase-less key (passphrase protection is provided by GitHub Secrets)
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: WPE WebKit Linux PPA
Name-Email: wpe-webkit-linux@sharpblue.com.au
Expire-Date: 0
%no-protection
%commit
EOF

# Get the key ID
gpg --list-secret-keys --keyid-format LONG wpe-webkit-linux@sharpblue.com.au

# Export to add as the GPG_PRIVATE_KEY secret
gpg --armor --export-secret-keys wpe-webkit-linux@sharpblue.com.au
```

## Packages produced

| Package | Contains |
|---------|----------|
| `libwpewebkit-1.0-3` | Runtime `.so` libraries |
| `libwpewebkit-1.0-dev` | Headers, unversioned `.so` symlink, pkg-config file |

## Consuming in Nightmail CI

In `.github/workflows/release.yml`, before installing `libwpewebkit-1.0-dev`:

```bash
curl -fsSL https://hobleyd.github.io/wpe-webkit-linux/wpe-webkit-linux.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/wpe-webkit-linux.gpg
echo "deb [signed-by=/usr/share/keyrings/wpe-webkit-linux.gpg] \
  https://hobleyd.github.io/wpe-webkit-linux/apt noble main" \
  | sudo tee /etc/apt/sources.list.d/wpe-webkit-linux.list
sudo apt-get update
sudo apt-get install -y libwpewebkit-1.0-dev
```
