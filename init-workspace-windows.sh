#!/bin/bash
export MSYS_NO_PATHCONV=1
SCRIPT_ROOT=$(dirname $0)

mkdir -p "$SCRIPT_ROOT/bin"
mkdir -p "$SCRIPT_ROOT/isos"

PACKER_VERSION='1.2.4'
VAGRANT_VERSION='2.1.1'

CENTOS_HASH_SIGNATURE='714acc0aefb32b7d51b515e25546835e55a90da9fb00417fbee2d03a62801efd'

downloadPacker=0
if [[ -f "$SCRIPT_ROOT/bin/packer.exe" ]]; then
  packerVersion=$("$SCRIPT_ROOT/bin/packer.exe" -v)
  if [[ "$packerVersion" != "$PACKER_VERSION" ]]; then
    downloadPacker=1
  fi
else
  downloadPacker=1
fi

if [[ "$downloadPacker" == "1" ]]; then
  curl "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_windows_amd64.zip" > "$SCRIPT_ROOT/bin/packer.zip"
  unzip -d "$SCRIPT_ROOT/bin" -o "$SCRIPT_ROOT/bin/packer.zip"
  rm "$SCRIPT_ROOT/bin/packer.zip"
fi

curl "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.msi" > "$SCRIPT_ROOT/bin/vagrant.msi"
powershell -Command "msiexec /i (Resolve-Path \"$SCRIPT_ROOT/bin/vagrant.msi\")"
