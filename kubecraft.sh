#!/bin/bash
source .env.example
source .env
./scripts/bootstrap/create.sh
./scripts/installcapi.sh "$BOOTSTRAPCLUSTER"
./scripts/mgmt/create.sh
./scripts/installcapi.sh "$MGMTCLUSTER"
./scripts/mgmt/move.sh
./scripts/bootstrap/teardown.sh