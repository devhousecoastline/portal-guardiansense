# Publica o portal web no Firebase Hosting.
# Sem service worker (--pwa-strategy=none) para deploys aparecerem na hora.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

flutter build web --release --pwa-strategy=none
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

firebase deploy --only hosting --project guardian-sense-dbdfa
exit $LASTEXITCODE
