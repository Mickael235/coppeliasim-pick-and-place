# Cellule robotisée — Pick-and-Place (CoppeliaSim)

Simulation d’une cellule robotisée avec convoyeur, **ABB IRB 140** et pince **RG2**, développée dans le cadre d’un projet de jumeau numérique de bras robotique.

**Auteur / contribution personnelle : Michael Essomba.** La contribution concerne notamment l’intégration et la coordination du scénario de convoyage, détection, préhension, transport et dépôt, ainsi que les vues de caméra et le tableau de bord. Les modèles de robot, pince et convoyeur proviennent de la bibliothèque CoppeliaSim et ne sont pas présentés comme des créations personnelles. Projet réalisé dans un contexte collaboratif ; les attributions complémentaires pourront être précisées.

## Démonstration

Le scénario vise **trois cycles** : arrivée d’une pièce, arrêt du convoyeur, prise avec RG2, transport, dépôt sur la table, retour du robot, puis pièce suivante. Les essais précédents ont montré trois cycles terminés et trois pièces immobilisées sur la table. **La reproduction de la version `scene/Cube2.ttt` après réouverture sur un autre poste reste à confirmer.** Le compteur indique des cycles terminés et ne constitue pas une vérification automatique complète de conformité du dépôt.

[Vidéo de démonstration (publication LinkedIn)](https://www.linkedin.com/feed/update/urn:li:activity:7521463799107735553/)

## Démarrage

1. Installer **CoppeliaSim Edu**, avec ses composants **simIK** et **simUI** disponibles.
2. Ouvrir `scene/Cube2.ttt`.
3. Vérifier que les modèles et scripts se chargent sans erreur.
4. Lancer la simulation avec **Play** et observer les pièces successives et le compteur de cycles.
5. Relever les éventuels messages d’erreur : ce dépôt est une **première exportation des sources**, pas encore une version qualifiée sur une installation propre.

Les scripts sont déjà intégrés à la scène `.ttt`. Le dossier `scripts/` en constitue un **export de référence** pour lecture, revue et suivi Git : il ne faut pas les réimporter en doublon.

## Structure

```text
scene/Cube2.ttt             Scène CoppeliaSim fournie
scripts/cell_controller.lua Contrôle des trois cycles et commandes d'équipements
scripts/irb140_ik.lua      Cinématique inverse
scripts/rg2.lua            Commande de la pince
scripts/conveyor.lua       Script du convoyeur
scripts/dynamic_camera.lua Vues de démonstration
scripts/dashboard.lua      Tableau de bord
scripts/irb140_legacy.lua  Ancien script d'approche (à vérifier/désactiver)
media/                      Emplacement pour la vidéo et les captures
```

## État des fonctionnalités

- **CoppeliaSim / Lua** : scénario de pick-and-place, trois cycles programmés, capteur, pince, retour au repos, caméras et tableau de bord.
- **ROS 2** : **non intégré** à cette scène. Intégration envisagée séparément.
- **Jumeau numérique connecté à un robot réel** : **non réalisé** dans cette version.
- **Détection par caméra, MoveIt ou IA** : **hors périmètre** de cette première version.

### Limites connues

- `scripts/irb140_legacy.lua` contient une ancienne logique d'approche pouvant entrer en conflit avec `cell_controller.lua` si activée simultanément ; son état *enabled* dans la scène reste à contrôler dans CoppeliaSim.
- Le contrôleur compte les cycles achevés ; il ne valide pas encore automatiquement l'emplacement et la stabilité de chaque pièce déposée.
- Les durées, collisions et résultats physiques doivent être recontrôlés depuis `Cube2.ttt`.

## Modèles et droits

Les scripts exportés incluent des scripts de modèles CoppeliaSim. Les droits et conditions de redistribution des modèles, scènes et bibliothèques dépendent de leur provenance/licence. Vérifier ces conditions avant toute publication publique ; ce dépôt ne prétend pas transférer ces droits.
