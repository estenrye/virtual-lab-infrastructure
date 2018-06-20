#!/bin/bash
export MSYS_NO_PATHCONV=1
SCRIPT_ROOT=$(dirname $0)


"$SCRIPT_ROOT/../../bin/cdrtools/win64/mkisofs.exe" -r -R -J -l -o "$SCRIPT_ROOT/preseed.iso" "$SCRIPT_ROOT/http"