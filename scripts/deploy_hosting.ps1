# Publica o portal web no Firebase Hosting.
# Sobe patch+build (pubspec + AppConstants), builda e faz deploy.
# Sem service worker (--pwa-strategy=none) para deploys aparecerem na hora.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

python scripts/bump_portal_version.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build web --release --pwa-strategy=none
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

firebase deploy --only hosting --project guardian-sense-dbdfa
exit $LASTEXITCODE
