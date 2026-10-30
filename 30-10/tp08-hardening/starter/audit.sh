#!/bin/sh
# Affiche le durcissement de chaque conteneur en cours d'exécution.
# Écart : user root, privileged, caps non retirées, rootfs writable,
# pas de limite mémoire, pas de PidsLimit, pas de no-new-privileges,
# socket Docker montée.
# Usage : ./audit.sh [projet compose]
# Code retour 1 s'il y a au moins un écart.

set -u

projet="${1:-}"
ecarts=0

for id in $(docker ps -q); do
  proj=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$id")
  if [ -n "$projet" ] && [ "$proj" != "$projet" ]; then
    continue
  fi

  nom=$(docker inspect -f '{{.Name}}' "$id" | sed 's|^/||')
  cfg_user=$(docker inspect -f '{{.Config.User}}' "$id")
  proc_user=$(docker top "$id" -o pid,user | awk 'NR==2 {print $2; exit}')
  [ -n "$proc_user" ] || proc_user=root
  if [ -n "$cfg_user" ]; then
    user="$cfg_user"
  else
    user="$proc_user (non défini au run)"
  fi
  priv=$(docker inspect -f '{{.HostConfig.Privileged}}' "$id")
  cap_add=$(docker inspect -f '{{json .HostConfig.CapAdd}}' "$id")
  cap_drop=$(docker inspect -f '{{json .HostConfig.CapDrop}}' "$id")
  ro=$(docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' "$id")
  mem=$(docker inspect -f '{{.HostConfig.Memory}}' "$id")
  pids=$(docker inspect -f '{{.HostConfig.PidsLimit}}' "$id")
  sec=$(docker inspect -f '{{json .HostConfig.SecurityOpt}}' "$id")
  binds=$(docker inspect -f '{{json .HostConfig.Binds}}' "$id")

  echo "$nom"
  echo "  user=$user privileged=$priv"
  echo "  cap_add=$cap_add cap_drop=$cap_drop"
  echo "  read_only=$ro memory=$mem pids_limit=$pids"
  echo "  security_opt=$sec"
  echo "  binds=$binds"

  probleme=""
  case "$user" in
    root*|0|0:*) probleme="$probleme user-root" ;;
  esac
  [ "$priv" = "true" ] && probleme="$probleme privileged"
  echo "$cap_drop" | grep -q 'ALL' || probleme="$probleme cap-drop"
  [ "$ro" = "true" ] || probleme="$probleme rootfs-rw"
  [ "$mem" -gt 0 ] 2>/dev/null || probleme="$probleme memory"
  case "$pids" in
    ""|"<nil>"|0) probleme="$probleme pids" ;;
  esac
  echo "$sec" | grep -q 'no-new-privileges' || probleme="$probleme no-new-privileges"
  echo "$binds" | grep -q 'docker.sock' && probleme="$probleme socket"

  if [ -n "$probleme" ]; then
    echo "  ECART:$probleme"
    ecarts=$((ecarts + $(printf '%s' "$probleme" | wc -w | tr -d ' ')))
  else
    echo "  ok"
  fi
  echo
done

echo "écarts: $ecarts"
if [ "$ecarts" -gt 0 ]; then
  exit 1
fi
exit 0
