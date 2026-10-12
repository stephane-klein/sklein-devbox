---
ai_origin: ai-drafted
ai_model: Claude Sonnet 4.6
date: 2026-06-18
reviewed_at: 2026-06-18
ai_note: Premier jet généré par Claude, puis retravaillé par l'utilisateur : ajout d'une citation de son propre article de juillet 2025 sur l'usage des LLM, attribution explicite du raisonnement sur le choix du mot « provenance » à Claude (Sonnet), suppression de la section sur le nom « note » vs « pkm ».
---

# note-ai-provenance

## Pourquoi ce skill

J'utilise de plus en plus des LLM dans mon travail d'écriture : pour générer un premier jet, reformuler un brouillon,
ou construire une note par allers-retours avec un agent.

Je ne veux pas que cet usage reste invisible. Quand quelqu'un lit une note sur <https://notes.sklein.xyz>, je veux qu'il puisse savoir,
sans avoir à me le demander, ce qui vient de moi, ce qui vient d'un modèle, et dans quelle mesure les deux se sont mélangés.

[En juillet 2025](https://notes.sklein.xyz/2025-07-15_2339/zen/), dans [J'utilise les LLMs comme des amis experts et jamais comme des écrivains fantômes](https://notes.sklein.xyz/2025-07-15_2339/zen/) j'écrivais ceci :

> Lorsque je trouve pertinent un contenu produit par un LLM, je le partage en tant que citation en indiquant clairement la version du modèle qui l'a généré. Je le cite comme je citerai les propos d'un humain.
> 
> En résumé, je ne m'attribue jamais les propos générés par un LLM. Je n'utilise jamais un LLM comme un écrivain fantôme.

Un an plus tard, j'essaie de suivre continuer à suivre cette discipline.

Ce n'est pas une démarche de certification ni un gage de rigueur absolue : c'est une déclaration de bonne foi,
faite au moment où la note est produite ou modifiée.

L'objectif est simple — transparence, modestie sur ce que j'ai réellement écrit moi-même, honnêteté envers qui me lit.


## Pourquoi "provenance" dans le nom de ce skill ?

Sonnet a écarté "authorship" (la paternité au sens propre suppose un auteur, ce qui colle mal aux cas de co-écriture
ou de premier jet IA retravaillé) et "attribution" (le mot évoque plutôt la citation de sources externes que le suivi
d'un processus d'écriture).

"Provenance" couvre les deux dimensions qui m'intéressent : d'où vient le texte, et quelles transformations il a subies depuis.

C'est aussi le terme déjà utilisé en data engineering ("data provenance") et dans les standards de transparence
sur le contenu IA (C2PA) — pas la peine de réinventer un mot quand un terme établi dit déjà ce qu'on veut dire.


## Ce que ce skill ne fait pas

Il ne détecte pas automatiquement la part d'IA dans un texte — il s'appuie sur ma déclaration au moment de
l'écriture ou de l'édition. Si je ne corrige pas le frontmatter après une retouche, l'information devient
fausse. Voir `SKILL.md` pour la procédure détaillée de mise à jour des champs.
