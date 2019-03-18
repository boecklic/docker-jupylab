#!/bin/bash

# Add local user
# Either use the LOCAL_UID if passed in at runtime or
# fallback

USER_ID=${LOCAL_UID:-1000}

echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m user
export HOME=/home/user
echo "$(ls -l /home)"

exec /usr/local/bin/gosu user "$@"
