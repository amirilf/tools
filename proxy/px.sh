#!/bin/bash

CONFIG_DIR="{the proxy dir path}"
CONFIG_FILE="{the config file path}"
CURRENT_PROFILE_FILE="{the current_profile path}"

set_profile() {
  local profile="$1"
  if [[ "$profile" == "off" ]]; then
    gsettings set org.gnome.system.proxy mode 'none'
    gsettings set org.gnome.system.proxy.http host ''
    gsettings set org.gnome.system.proxy.http port 0
    gsettings set org.gnome.system.proxy.https host ''
    gsettings set org.gnome.system.proxy.https port 0
    gsettings set org.gnome.system.proxy ignore-hosts "[]"
    echo "off" > "$CURRENT_PROFILE_FILE"
    echo "Proxy disabled"
    return
  fi

  http_proxy=$(awk -F= -v p="$profile" -v k="http" '$0 ~ "\\["p"\\]" { inside=1 } inside && $1 == k { print $2; exit }' "$CONFIG_FILE")
  https_proxy=$(awk -F= -v p="$profile" -v k="https" '$0 ~ "\\["p"\\]" { inside=1 } inside && $1 == k { print $2; exit }' "$CONFIG_FILE")
  ignore_hosts=$(awk -F= -v p="$profile" -v k="ignore" '$0 ~ "\\["p"\\]" { inside=1 } inside && $1 == k { print $2; exit }' "$CONFIG_FILE")

  if [[ -z "$http_proxy" && -z "$https_proxy" ]]; then
    echo "Profile '$profile' not found"
    exit 1
  fi

  gsettings set org.gnome.system.proxy mode 'manual'
  [[ -n "$http_proxy" ]] && gsettings set org.gnome.system.proxy.http host "${http_proxy%:*}" && gsettings set org.gnome.system.proxy.http port "${http_proxy#*:}"
  [[ -n "$https_proxy" ]] && gsettings set org.gnome.system.proxy.https host "${https_proxy%:*}" && gsettings set org.gnome.system.proxy.https port "${https_proxy#*:}"

  if [[ -n "$ignore_hosts" ]]; then
    IFS=',' read -r -a ignore_array <<< "$ignore_hosts"
    gsettings set org.gnome.system.proxy ignore-hosts "$(printf '%s\n' "${ignore_array[@]}" | jq -R . | jq -s .)"
  else
    gsettings set org.gnome.system.proxy ignore-hosts "[]"
  fi

  echo "$profile" > "$CURRENT_PROFILE_FILE"
  echo "Proxy set to '$profile'"
}

status() {
  current_mode=$(gsettings get org.gnome.system.proxy mode)
  echo -e "Proxy Status: ${current_mode//\'/}"
  if [[ "$current_mode" == "'manual'" ]]; then
    current_profile=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "unknown")
    echo -e "Active Profile: $current_profile"
    echo -e "HTTP:  $(gsettings get org.gnome.system.proxy.http host | tr -d \'):$(gsettings get org.gnome.system.proxy.http port)"
    echo -e "HTTPS: $(gsettings get org.gnome.system.proxy.https host | tr -d \'):$(gsettings get org.gnome.system.proxy.https port)"
    ignore_hosts=$(gsettings get org.gnome.system.proxy ignore-hosts)
    echo -e "Ignored Hosts: ${ignore_hosts}"
  fi
}

case "$1" in
  edit)
    nano "$CONFIG_FILE"
    current_profile=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "off")
    set_profile "$current_profile"
    ;;
  off)  set_profile "off" ;;
  "")   status ;;
  *)    set_profile "$1" ;;
esac