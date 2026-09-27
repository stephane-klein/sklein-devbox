---
name: sklein-todo
description: "Gère la todo list de Stéphane via la banque mémoire hindsight `todo` et le sous-agent `@todo`. Use when user says: ajoute à ma todo, marque comme fait, liste mes tâches, supprime une tâche, bloque/débloque une tâche, quelles sont mes priorités, importe ça dans ma todo, ou colle un bloc de texte contenant plusieurs tâches."
---

# sklein-todo

Quand l'utilisateur fait une demande liée à sa todo list, **ne pas traiter
directement**. Déléguer au sous-agent `@todo` via le tool `task` :

```
task(
  description: "todo operation",
  subagent_type: "general",
  prompt: "Tu es l'assistant todo list de Stéphane. Utilise exclusivement les outils MCP hindsight avec `bank_id: \"todo\"`.

## Conventions de tags
Tags obligatoires : `status:x`, `priority:x`
Tags optionnels : `context:x`
Vocabulaire status : pending | in_progress | done | blocked | cancelled
Vocabulaire priority : critical | high | medium | low
Priorité par défaut : medium.

## Demande de l'utilisateur
<insérer ici la demande textuelle de l'utilisateur>

Exécute l'opération correspondante (ajout, import batch, mise à jour de statut, consultation, suppression) et retourne le résultat."
)
```

## Déclencheurs

| Intent | Exemples |
|---|---|
| Ajout simple | « ajoute X à ma todo », « ajoute X », « todo : X », « rappelle-moi de X » |
| Import batch | « importe ça dans ma todo », ou bloc de texte 2+ lignes / 3+ tâches |
| Mise à jour statut | « marque X comme fait/done/terminé », « X est bloqué parce que Y », « mets X en cours », « annule X » |
| Consultation | « quelles sont mes priorités ? », « qu'est-ce qui est bloqué ? », « liste mes tâches », « qu'ai-je fait aujourd'hui ? » |
| Suppression | « supprime X », « enlève X de ma todo », « vire X » |

## Exemples

```
> ajoute rédiger le rapport mensuel à ma todo
→ dispatch vers @todo avec prompt : "Ajoute la tâche 'rédiger le rapport mensuel' à la todo (priority:medium)"

> importe ça dans ma todo :
  - finir la spec API
  - envoyer la facture à Dupont (urgent)
→ dispatch vers @todo avec prompt : "Importe ces tâches en batch : ..."

> quelles sont mes priorités ?
→ dispatch vers @todo avec prompt : "Quelles sont les tâches les plus importantes à faire maintenant ?"
```
