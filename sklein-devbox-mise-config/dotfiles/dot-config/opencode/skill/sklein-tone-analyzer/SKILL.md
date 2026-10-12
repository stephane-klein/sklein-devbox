---
name: sklein-tone-analyzer
description: >
  Analyse si un texte adopte un registre professoral ou non, et identifie les
  mécanismes précis qui le produisent. Utilise ce skill dès que l'utilisateur
  demande à évaluer le ton d'un texte, à détecter un style académique ou
  professoral, à rendre un texte moins formel ou moins distant, ou à vérifier
  si une écriture "sonne" trop théorique, trop scolaire, ou trop savante.
  Déclenche aussi si l'utilisateur colle un extrait et demande un retour sur
  le style, le ton, ou la lisibilité.
---

# Tone Analyzer — Registre professoral

## Objectif

Produire une analyse structurée qui répond à : **ce texte adopte-t-il un
registre professoral, et pourquoi ?** L'analyse doit être actionnable —
chaque signal identifié doit pointer vers une reformulation possible.

---

## Définition du registre professoral

Le registre professoral se caractérise par une **mise à distance de
l'énonciateur** : le texte donne l'impression de parler depuis nulle part,
au nom d'une vérité générale. Il se distingue du registre conversationnel ou
réflexif (journal, essai personnel, PKM) par plusieurs mécanismes cumulatifs.

Le registre professoral n'est pas intrinsèquement mauvais — il est adapté
à certains contextes (article de revue, rapport formel, thèse). Le problème
survient quand il est utilisé hors contexte, notamment dans des écrits
personnels, des notes de réflexion, ou des billets de blog.

---

## Signaux à détecter

### 1. Effacement du sujet énonciateur

Formes passives impersonnelles ou pronoms génériques qui évitent le "je" :
- "on constate que", "il apparaît que", "il convient de noter"
- "cela démontre", "force est de constater", "il s'avère que"
- "nous verrons que", "comme nous allons le montrer"

**Contraste sain** : marqueurs de modestie épistémique ("il me semble que",
"mon intuition serait que", "je n'arrive pas encore à trancher") — ceux-ci
assument une position sans prétendre à l'objectivité universelle.

### 2. Rhétorique du plan annoncé

À distinguer du plan *structurel* (headers, sections) qui est neutre ou
positif pour la navigabilité. Le signal professoral, c'est le plan *énoncé
dans la prose* — l'auteur explique dans le texte lui-même ce qu'il va dire
ou vient de dire :

- "En premier lieu... en second lieu... enfin..."
- "Après avoir vu X, nous aborderons Y"
- Introduction récapitulant ce qui va être dit
- Conclusion récapitulant ce qui vient d'être dit ("Ainsi, nous avons vu que...")

**Non-signal** : des headers Markdown ou titres de section bien nommés
rendent le plan visible sans l'énoncer rhétoriquement — c'est une aide à
la navigation, pas de la professoralité.

### 3. Nominalisation excessive

Transformer des verbes ou adjectifs en substantifs alourdit et distancie :
- "la problématisation de cette question" → "comment poser ce problème"
- "une mise en perspective" → "replacer dans le contexte"
- "l'opérationnalisation du concept" → "comment appliquer l'idée"

### 4. Lexique de surplomb

Vocabulaire qui signale la maîtrise du domaine plutôt que d'expliquer :
- termes techniques non définis quand le contexte n'est pas spécialisé
- latinismes ou gallicismes formels sans nécessité ("ipso facto", "partant",
  "nonobstant")
- adverbes lourds : "nécessairement", "fondamentalement", "intrinsèquement"

### 5. Transitions formelles entre paragraphes

Connecteurs logiques surexplicités :
- "Ainsi, nous pouvons affirmer que..."
- "Dès lors, il convient de s'interroger sur..."
- "C'est dans cette perspective que..."
- "Au regard de ce qui précède..."

### 6. Absence de traces du cheminement

Le texte présente des conclusions sans montrer les hésitations, les
fausses pistes, ou les questions non résolues. Tout paraît déjà tranché.

**Contraste sain** : "je ne sais pas encore si...", "ce point me résiste",
"j'ai changé d'avis en écrivant ces lignes".

### 7. Longueur et rythme des phrases

Phrases longues à propositions enchâssées multiples, sans variation de
rythme. Le professoral évite les phrases courtes, sèches, incisives.

---

## Format de l'analyse

Produire l'analyse en trois parties :

### Verdict global

Une à deux phrases synthétiques : le texte est-il majoritairement
professoral, hybride, ou conversationnel/réflexif ? Préciser si c'est
léger, marqué, ou très marqué.

### Signaux détectés

Pour chaque signal présent, citer **l'extrait exact** du texte source, nommer
le mécanisme (parmi les 7 ci-dessus), et proposer une reformulation
alternative plus directe ou incarnée.

Format pour chaque occurrence :
```
> [extrait original]
Mécanisme : [nom du signal]
Alternative : [reformulation proposée]
```

Ne lister que les signaux effectivement présents. Si un texte n'a aucun
signal, le dire clairement.

### Bilan

- Densité : nombre de signaux / nombre de paragraphes (ou lignes)
- Signaux dominants : les 1-2 mécanismes les plus fréquents
- Conseil principal : une seule action prioritaire pour améliorer le texte

---

## Nuances importantes

**Ne pas confondre rigueur et professoralité.** Un texte peut être précis,
sourcé, structuré et non professoral. Les marqueurs de [modestie épistémique](https://notes.sklein.xyz/Marqueur%20de%20modestie%20%C3%A9pist%C3%A9mique/)
sont des indicateurs positifs — leur présence compense partiellement les autres signaux.

**Le contexte détermine le verdict.** Un article de revue académique avec
des signaux professoraux est adapté à son usage. Une note de PKM ou un billet
de blog avec les mêmes signaux est hors registre.

**Seuil de tolérance par type de texte :**

| Type de texte       | Signaux tolérés | Seuil d'alerte |
|---------------------|-----------------|----------------|
| PKM / journal       | 0–1             | ≥ 2            |
| Billet de blog      | 1–2             | ≥ 3            |
| Essai personnel     | 2–3             | ≥ 4            |
| Article de fond     | 3–5             | ≥ 6            |
| Article académique  | illimité        | —              |

Si le type de texte n'est pas précisé, demander avant de rendre le verdict
final, ou formuler l'analyse pour les deux cas les plus probables.

---

## Exemple de verdict attendu

> **Verdict** : Hybride, tendance professoral légère. Deux mécanismes
> récurrents : effacement du sujet et transitions formelles. Le fond est
> réflexif mais la forme crée une distance inutile.
>
> **Signal 1**
> > "Il convient de noter que cette approche présente des limites."
> Mécanisme : effacement du sujet
> Alternative : "Je vois au moins une limite à cette approche."
>
> **Signal 2**
> > "Dès lors, on peut se demander si..."
> Mécanisme : transition formelle + effacement du sujet
> Alternative : "Ça me pose une question : est-ce que..."
>
> **Bilan** : 2 signaux / 4 paragraphes. Dominante : effacement du sujet.
> Conseil : remplacer systématiquement les constructions impersonnelles par
> des formulations à la première personne, avec ou sans marqueur de modestie.
