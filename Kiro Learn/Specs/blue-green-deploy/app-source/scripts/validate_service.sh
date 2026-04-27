#!/bin/bash
# ValidateService hook - verify the application is running

echo "ValidateService: checking that the app is reachable..."

for i in 1 2 3 4 5; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "ValidateService: app returned HTTP 200 - success"
        exit 0
    fi
    echo "ValidateService: attempt $i - got HTTP $HTTP_CODE, retrying in 5s..."
    sleep 5
done

echo "ValidateService: app did not return HTTP 200 after 5 attempts"
exit 1
