#!/usr/bin/env bash
set -euo pipefail

echo "Levantando laboratorio TSIGE..."
docker compose up -d

echo ""
./scripts/vm_smoke_test.sh

echo ""
echo "Laboratorio listo."
echo "Abrir en el navegador de la VM:"
echo "http://localhost:8081"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open http://localhost:8081 >/dev/null 2>&1 || true
fi
