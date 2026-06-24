# wpe-webkit-linux — Claude Code Guide

## Purpose

Builds WPEWebKit 2.42.x (last stable series with the `wpewebkit-1.0` pkg-config ABI)
on Ubuntu 24.04 (Noble) and publishes `.deb` packages to an APT repository at
`wpe-webkit-linux.sharpblue.com.au`.

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

Target: **2.42.x** (the latest 2.42.y patch release).
- The `wpewebkit-1.0` pkg-config ABI is present in 2.36–2.42.
- 2.44+ switches to `wpewebkit-2.0` (different ABI, different library SONAME).
- Do not update past 2.42.x without checking `flutter_inappwebview_linux`.

## APT repository

URL: `http://wpe-webkit-linux.sharpblue.com.au/apt`
Codename: `noble`
Component: `main`
GPG key: `http://wpe-webkit-linux.sharpblue.com.au/wpe-webkit-linux.gpg`

## Server setup

Run `server/setup.sh` once on the server. It installs nginx + reprepro and
initialises the repo structure. Set `GPG_KEY_ID` to your signing key.

## GitHub Actions secrets required

| Secret | Description |
|--------|-------------|
| `REPO_SSH_KEY` | Private SSH key for the deploy user on the repo server |
| `REPO_USER` | SSH username on `wpe-webkit-linux.sharpblue.com.au` |

## Packages produced

| Package | Contains |
|---------|----------|
| `libwpewebkit-1.0-3` | Runtime `.so` libraries |
| `libwpewebkit-1.0-dev` | Headers, unversioned `.so` symlink, pkg-config file |

## Consuming in Nightmail CI

In `.github/workflows/release.yml`, before installing `libwpewebkit-1.0-dev`:

```bash
curl -fsSL http://wpe-webkit-linux.sharpblue.com.au/wpe-webkit-linux.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/wpe-webkit-linux.gpg
echo "deb [signed-by=/usr/share/keyrings/wpe-webkit-linux.gpg] \
  http://wpe-webkit-linux.sharpblue.com.au/apt noble main" \
  | sudo tee /etc/apt/sources.list.d/wpe-webkit-linux.list
sudo apt-get update
sudo apt-get install -y libwpewebkit-1.0-dev
```
