#!/bin/sh
# Join the tailnet, and let tailscaled answer ssh so no keys are needed between machines.

command -v tailscale >/dev/null 2>&1 || exit 0

# The tailnet name follows the yadm class, so the same script names each machine.
case "$(yadm config local.class 2>/dev/null)" in
work) tailnet_hostname=work-laptop ;;
personal) tailnet_hostname=home-laptop ;;
*) tailnet_hostname=$(hostname) ;;
esac

sudo tailscale up \
    --ssh \
    --accept-dns=false \
    --accept-routes=false \
    --hostname="$tailnet_hostname" \
    --operator="$USER"

tailscale status
