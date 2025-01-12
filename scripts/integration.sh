#!/usr/bin/env bash
set -ex
set -o pipefail

if [ ! -f genfiles/server.key ]; then
	./scripts/prepare_server.sh -f
fi

docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
trap "docker-compose down" INT EXIT

wget -T 60 --spider --retry-connrefused --waitretry=1 http://localhost:8081/metrics
wget -T 60 -O /dev/null --no-check-certificate  \
	--retry-connrefused --waitretry=1 \
	--retry-on-http-error=405,404 \
	https://localhost/v1/directories/default

PASSWORD="foobar"
go run ./cmd/keytransparency-client authorized-keys create-keyset --password=${PASSWORD}
go run ./cmd/keytransparency-client post foo@bar.com \
	--insecure \
	--data='dGVzdA==' \
	--password=${PASSWORD} \
	--kt-url=localhost:443 \
	--verbose \
	--logtostderr
