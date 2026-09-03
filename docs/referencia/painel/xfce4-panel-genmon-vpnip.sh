#!/bin/sh

interface="$1"

[ -z "$interface" ] && interface="$(ip tuntap show | cut -d : -f1 | head -n 1)"
ip="$(ip addr show "${interface}" 2>/dev/null \
        | grep -o -P '(?<=inet )[0-9]{1,3}(\.[0-9]{1,3}){3}')"

if [ "${ip}" != "" ]; then
  printf "<icon>network-vpn-symbolic</icon>"
  printf "<txt>${ip}</txt>"
  if command -v xclip; then
    printf "<iconclick>sh -c 'printf ${ip} | xclip -selection clipboard'</iconclick>"
    printf "<txtclick>sh -c 'printf ${ip} | xclip -selection clipboard'</txtclick>"
    printf "<tool>VPN IP (click to copy)</tool>"
  else
    printf "<tool>VPN IP (install xclip to copy to clipboard)</tool>"
  fi
else
  printf "<txt></txt>"
fi

