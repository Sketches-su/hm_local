#!/bin/sh

set -e
fakemail_mailbox="`dirname "$0"`/../../mail"
hm_install_path="`readlink -f "$0"`"
hm_install_path="`dirname "$hm_install_path"`"
. "$hm_install_path/config"

mailfile="$fakemail_mailbox/`date '+%Y-%m-%d_%H-%M-%S_%N'`.txt"

echo "Command line arguments: $@" > "$mailfile"
echo >> "$mailfile"
cat >> "$mailfile"

/bin/true
