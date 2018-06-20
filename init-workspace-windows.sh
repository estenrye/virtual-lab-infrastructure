#!/bin/bash
export MSYS_NO_PATHCONV=1
SCRIPT_ROOT=$(dirname $0)

mkdir -p "$SCRIPT_ROOT/bin"
mkdir -p "$SCRIPT_ROOT/isos"
mkdir -p "$SCRIPT_ROOT/bin/cdrtools"

PACKER_VERSION='1.2.4'
VAGRANT_VERSION='2.1.1'
CENTOS_HASH_SIGNATURE='714acc0aefb32b7d51b515e25546835e55a90da9fb00417fbee2d03a62801efd'
Z7='C:\Program Files\7-Zip\7z.exe'


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

downloadVagrant=0
if [[ ! -z $(vagrant -v) ]]; then
  if [[ "Vagrant $VAGRANT_VERSION" != "$(vagrant -v)" ]]; then
    downloadVagrant=1
  fi
fi

if [[ "$downloadVagrant" == "1" ]]; then
  curl "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.msi" > "$SCRIPT_ROOT/bin/vagrant.msi"
  powershell -Command "msiexec /i (Resolve-Path \"$SCRIPT_ROOT/bin/vagrant.msi\")"
fi

# curl "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" > "$SCRIPT_ROOT/bin/nuget.exe"

#  ./bin/nuget.exe install Discutils -version 0.13.0-alpha -o lib

curl "https://phoenixnap.dl.sourceforge.net/project/tumagcc/schily-cdrtools-3.02a05.7z" > "$SCRIPT_ROOT/bin/cdrtools.7z"
cd "$SCRIPT_ROOT/bin/cdrtools"
"$Z7" x "../cdrtools.7z"