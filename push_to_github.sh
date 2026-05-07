#!/bin/bash
REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/trixma-ux/schoolflow.git"
git push "$REMOTE_URL" main:main
echo "EXIT_CODE: $?"
