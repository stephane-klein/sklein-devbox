---
name: sklein-ssh-push-deploy
description: Script de déploiement par envoi de payload via SSH sans Ansible.
---

# Déploiement SSH push en deux fichiers (launcher + payload)

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande de :

- Créer un script de déploiement SSH push
- Générer un couple `deploy_*.sh` / `_payload_deploy_*.sh`
- Exécuter des commandes à distance via SSH avec injection de variables
- Créer un script "remote task execution" avec minijinja-cli

Lorsque l'activation correspond à un contexte où Ansible serait une alternative
envisageable (déploiement, configuration distante, exécution de tâches à distance),
l'assistant doit **explicitement demander** à l'utilisateur :

> Veux-tu un script SSH push (launcher + payload) ou utiliser Ansible ?

## Dépendance

- **minijinja-cli** : installé avec Mise :

  ```toml
  [tools]
  ...
  "github:mitsuhiko/minijinja" = "2.20.0"
  ...
  ```

## Structure

```
deploy_<target>.sh              # Launcher (local)
_payload_deploy_<target>.sh     # Payload (exécuté à distance, template Jinja2)
```

## Principe

Le launcher utilise `minijinja-cli --env` pour injecter des variables d'environnement
dans le payload (template Jinja2), puis pipe le résultat dans une session SSH :

```bash
minijinja-cli --env _payload_deploy_<target>.sh | ssh user@host 'bash -s'
```

Le payload contient toutes les commandes à exécuter sur le serveur distant :
création de dossiers, écriture de fichiers, téléchargement, démarrage de services, etc.

## Conventions

### Launcher (`deploy_<target>.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

minijinja-cli --env _payload_deploy_<target>.sh | ssh <user>@$<SERVER_IP> 'bash -s'
```

Règles :
- `set -euo pipefail` pour la robustesse
- `cd "$(dirname "$0")"` pour être insensible au répertoire d'appel
- Paramètres et secrets passés via des variables d'environnement
- L'hôte SSH peut être une variable d'environnement ou un paramètre
- Documenter les variables d'environnement attendues en commentaire en haut du fichier

### Payload (`_payload_deploy_<target>.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Commandes exécutées à distance
# Utiliser {{ ENV.VARNAME }} pour les paramètres injectés par minijinja-cli --env
```

Règles :
- `set -euo pipefail` en tête
- Syntaxe `{{ ENV.VARNAME }}` pour toute valeur qui diffère entre exécutions
- Écrire les fichiers avec `cat <<'EOF' > chemin` (EOF entre quotes pour éviter
  l'expansion des variables shell locales par le heredoc)
- Le script doit être autonome et idempotent dans la mesure du possible
- Toujours nettoyer les fichiers temporaires en fin de payload si créés

## Workflow

1. **Déterminer l'opération distante** (créer des dossiers, écrire des fichiers de config,
   lancer des commandes, redémarrer un service, etc.)
2. **Identifier les paramètres variables** (IP, ports, mots de passe, tokens, etc.)
   qui seront injectés par minijinja-cli
3. **Créer le payload** (`_payload_deploy_<target>.sh`) avec toutes les commandes
   distantes et les placeholders `{{ ENV.VARNAME }}`
4. **Créer le launcher** (`deploy_<target>.sh`) avec le pipe `minijinja-cli --env | ssh`
5. **Rendre le launcher exécutable** : `chmod +x deploy_<target>.sh`
6. **Ne pas rendre le payload exécutable** (il est fait pour être pipé, pas lancé directement)

## Utilisation

```bash
export SERVER_IP="203.0.113.42"
export DB_PASSWORD="$(gopass show ...)"
export TOKEN="$(gopass show ...)"

./deploy_mon_service.sh
```

## Idempotence

Le payload devrait être écrit pour être exécuté plusieurs fois de suite sans effet
de bord (ou avec un effet de bord acceptable). Par exemple :

- `mkdir -p` plutôt que `mkdir`
- `cat <<EOF > fichier` écrase le fichier existant (attention : `>`, pas `>>`)
- Pour un service : `systemctl restart svc || systemctl start svc`

## Template Jinja2 dans le payload

Les parties du payload qui doivent être évaluées par minijinja-cli utilisent
la syntaxe Jinja2 standard :

- `{{ ENV.MA_VARIABLE }}` — insère la valeur de la variable d'environnement
- `{% if ENV.DEBUG %}set -x{% endif %}` — conditionnel
- `{% for key in ENV.HOSTS.split(',') %}...{% endfor %}` — boucle

**Attention** : dans un heredoc (`cat <<EOF`), le shell évalue `$var` et les backticks.
Pour éviter ça, toujours quoter le délimiteur : `cat <<'EOF'` ou `cat <<'HEREDOC'`.

## Variantes possibles

- Plusieurs payloads pour une même cible : `_payload_install_<target>.sh`,
  `_payload_upgrade_<target>.sh`, `_payload_backup_<target>.sh`
- Plusieurs launchers vers la même cible : `deploy_<target>.sh`, `backup_<target>.sh`

## Références

- [Notes sklein.xyz - Remote Task Execution](https://notes.sklein.xyz/Remote%20Task%20Execution%20(DevOps)/)
- [minijinja-cli](https://github.com/mitsuhiko/minijinja/tree/main/minijinja-cli)
- [poc-bash-ssh-docker-deployement-example](https://github.com/stephane-klein/poc-bash-ssh-docker-deployement-example)
