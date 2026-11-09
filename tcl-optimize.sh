#!/usr/bin/env bash
# Optimisation TCL Google TV via ADB Wi-Fi (macOS)
# Prérequis TV : Options développeur > Débogage USB activé.
# Usage : ./tcl-optimize.sh [IP_TV]     ou     ./tcl-optimize.sh --restore
set -euo pipefail
cd "$(dirname "$0")"

# 1) adb
if ! command -v adb >/dev/null; then
  echo "→ Installation d'adb (Homebrew)…"
  brew install --cask android-platform-tools
fi

# 2) Trouver la TV (port 5555 ouvert sur le sous-réseau)
TV_IP="${1:-}"
if [[ "$TV_IP" == "--restore" ]]; then RESTORE=1; TV_IP="${2:-}"; else RESTORE=0; fi
if [[ -z "$TV_IP" ]]; then
  MY_IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
  NET=${MY_IP%.*}
  echo "→ Recherche de la TV sur $NET.0/24 (port 5555)…"
  for i in $(seq 1 254); do
    ( nc -z -G 1 "$NET.$i" 5555 2>/dev/null && echo "$NET.$i" >> .found ) &
  done; wait
  TV_IP=$(head -1 .found 2>/dev/null || true); rm -f .found
  [[ -z "$TV_IP" ]] && { echo "✗ TV introuvable. Relance avec l'IP : ./tcl-optimize.sh 192.168.x.x"; exit 1; }
fi
echo "→ Connexion à $TV_IP… (accepte « Autoriser le débogage » sur la TV, coche « Toujours »)"
adb connect "$TV_IP:5555"
sleep 3
adb -s "$TV_IP:5555" get-state >/dev/null || { echo "✗ Non autorisé : accepte le prompt sur la TV puis relance."; exit 1; }
A="adb -s $TV_IP:5555 shell"

if [[ $RESTORE == 1 ]]; then
  echo "→ Restauration…"
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do $A settings put global $k 1.0; done
  $A pm enable com.google.android.apps.tv.launcherx || true
  if [[ -f disabled-packages.txt ]]; then
    while read -r p; do [[ -n "$p" ]] && $A cmd package install-existing "$p" </dev/null || true; done < disabled-packages.txt
  fi
  echo "✓ Restauré."; exit 0
fi

# 3) Infos + sauvegarde des listes de paquets
echo "→ Modèle : $($A getprop ro.product.model)  |  Android : $($A getprop ro.build.version.release)"
$A pm list packages    | sed 's/package://' | sort > packages-all.txt
$A pm list packages -3 | sed 's/package://' | sort > packages-user.txt
grep -iE 'tcl|tclchannel|tcl.*(store|game|ad)' packages-all.txt > packages-tcl.txt || true
echo "  Listes enregistrées : packages-all.txt, packages-user.txt, packages-tcl.txt"

# 4) Animations à 0.5x (réversible avec --restore)
for k in window_animation_scale transition_animation_scale animator_duration_scale; do $A settings put global $k 0.5; done
echo "✓ Animations réglées à 0.5x"

# 5) Ouvrir Projectivy Launcher dans le Play Store (installation manuelle avec la télécommande)
$A am start -a android.intent.action.VIEW -d "market://details?id=com.spocky.projengmenu" >/dev/null
echo "✓ Page Projectivy Launcher ouverte sur la TV — clique « Installer »."

# 6) Débloat : NON automatique. Édite debloat.txt (un paquet par ligne) puis :
if [[ -s debloat.txt ]]; then
  echo "→ Suppression (utilisateur 0, réversible) des paquets de debloat.txt…"
  while read -r p; do
    [[ -z "$p" || "$p" == \#* ]] && continue
    case "$p" in *gms*|*vending*|*tungsten*|*setupwraith*|*launcherx*|*android.tv.settings*) echo "  ⚠ ignoré (critique) : $p"; continue;; esac
    $A pm uninstall --user 0 "$p" </dev/null && echo "$p" >> disabled-packages.txt
  done < debloat.txt
fi
echo "✓ Terminé."
