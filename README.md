# wpe-webkit-linux

Builds `libwpewebkit-1.0-dev` for Ubuntu 24.04 (Noble) and publishes it to an APT
repository at `wpe-webkit-linux.sharpblue.com.au`.

## Why this exists

`flutter_inappwebview_linux` requires `wpewebkit-1.0` (pkg-config) which is not
available in Ubuntu 24.04's package archive. Debian Sid has `libwpewebkit-2.0-dev`
(a different ABI) compiled against glibc 2.42, which crashes on Ubuntu 24.04's
glibc 2.39. This project builds the correct version from source.

## Using the APT repository

```bash
curl -fsSL http://wpe-webkit-linux.sharpblue.com.au/wpe-webkit-linux.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/wpe-webkit-linux.gpg

echo "deb [signed-by=/usr/share/keyrings/wpe-webkit-linux.gpg] \
  http://wpe-webkit-linux.sharpblue.com.au/apt noble main" \
  | sudo tee /etc/apt/sources.list.d/wpe-webkit-linux.list

sudo apt-get update
sudo apt-get install libwpewebkit-1.0-dev
```

## Building

Trigger the **build-wpewebkit** workflow from GitHub Actions (Actions → build-wpewebkit
→ Run workflow). The default version is `2.42.5`. Do not change to 2.44+ — that
series uses the `wpewebkit-2.0` ABI which `flutter_inappwebview_linux` does not support.

The first build takes ~90 minutes. Subsequent runs use the cmake cache and are much faster.

## Server setup

On the server at `wpe-webkit-linux.sharpblue.com.au`:

1. Generate a GPG signing key: `gpg --full-generate-key`
2. Note the key ID: `gpg --list-keys`
3. Run: `sudo bash server/setup.sh <KEY_ID>`
4. Add `REPO_SSH_KEY` and `REPO_USER` secrets to this GitHub repository.

## Packages

| Package | Description |
|---------|-------------|
| `libwpewebkit-1.0-3` | Runtime libraries |
| `libwpewebkit-1.0-dev` | Development headers and pkg-config |
