#!/bin/bash
SITES=("direction" "comptabilite" "paie" "rh" "ce" "it" "production" "formation" "achat" "commercial" "client" "juridique" "blog")

echo "--- Test des sites Optimedit (HTTPS - Port 443) ---"
for app in "${SITES[@]}"; do
    url="https://$app.optimedit.eu"
    status=$(curl -o /dev/null -s -w "%{http_code}" -k "$url")
    
    if [ "$status" = "000" ]; then
        status="DOWN / Port 443 fermé (Vérifier IIS ou Certificat)"
    fi
    
    echo "[$app] -> $url : HTTP $status"
done
