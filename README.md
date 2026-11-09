# TCL Google TV : optimisation via ADB

Petit script macOS qui se connecte à une TV Google TV (TCL) en Wi-Fi via ADB, et :

- réduit les animations système à 0.5x (réversible) ;
- sauvegarde la liste des paquets installés (tous, utilisateur, et ceux liés à TCL) ;
- ouvre une alternative de lanceur (Projectivy) dans le Play Store pour installation manuelle ;
- supprime des paquets choisis par toi, **uniquement** ceux listés dans `debloat.txt` (suppression pour l'utilisateur 0, réversible).

## Prérequis

- macOS avec Homebrew (le script installe `adb` s'il manque).
- Sur la TV : *Options développeur* > *Débogage USB* activé. Accepter la demande « Autoriser le débogage » et cocher « Toujours ».
- La TV et le Mac sur le même réseau Wi-Fi.

## Utilisation

```bash
chmod +x tcl-optimize.sh
./tcl-optimize.sh                  # cherche la TV sur le sous-réseau (port 5555)
./tcl-optimize.sh 192.168.1.42     # ou donne l'IP directement
./tcl-optimize.sh --restore 192.168.1.42   # annule les animations et réactive le lanceur
```

Le script crée ses fichiers (`packages-*.txt`, `disabled-packages.txt`) dans le dossier où il se trouve.

## Débloat : à faire toi-même

Le script ne supprime rien automatiquement. Crée un fichier `debloat.txt` (un paquet par ligne, `#` pour les commentaires), puis relance le script. Quelques règles de prudence :

- Ne touche pas aux services Google indispensables (Play Store, Play Services) ni aux services HDMI/CEC et image du constructeur. Le script refuse déjà de supprimer les paquets critiques connus (`gms`, `vending`, `tungsten`, `setupwraith`, `launcherx`, `android.tv.settings`).
- Commence petit, liste les paquets un par un, et garde `--restore` sous la main.

Les réglages d'image et de jeu (HDMI 2.1, VRR, mode jeu) ne sont pas accessibles par ADB : ils se font à la télécommande.

## Avertissement

Projet personnel, testé sur une TCL Google TV. Aucune garantie : les noms de paquets et les menus varient selon les modèles et les versions d'Android. Tu agis à tes risques.

## Licence

MIT
