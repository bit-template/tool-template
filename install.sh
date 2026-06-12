#!/usr/bin/env bash
echo "── Common Bootstrap Script ──"

#--------------------------------------------------------------------
# 1) Define variables
#    - Set values via environment before running.
#    - Keep defaults empty to avoid errors if not updated.
#    - Example usage: export VAR_ONE="value"
#--------------------------------------------------------------------
## CODE
#: "${VAR_ONE:=$(read -rp "Linux username to run service (VAR_ONE): " tmp && echo "$tmp")}"
#: "${VAR_TWO:=$(read -rp "Linux username to run service (VAR_TWO): " tmp && echo "$tmp")}"
#: "${VAR_THREE:=$(read -rp "Linux username to run service (VAR_THREE): " tmp && echo "$tmp")}"

#--------------------------------------------------------------------
# 2) Export variables for downstream tasks
#    - Add new variables here if introduced above.
#    - This ensures they are available to Gradle or other scripts.
#--------------------------------------------------------------------
## CODE
# export VAR_ONE VAR_TWO VAR_THREE
# export EXTRA_VAR   # <--- add new exports here if needed

# call install script under src/install.sh
./gradlew install
