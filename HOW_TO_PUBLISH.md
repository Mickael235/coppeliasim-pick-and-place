# Publier sur GitHub

Depuis un terminal **dans ce dossier** :

```powershell
git init
git add .
git commit -m "Initial export: CoppeliaSim pick-and-place cell"
git branch -M main
git remote add origin https://github.com/TON_COMPTE/coppeliasim-pick-and-place.git
git push -u origin main
```

Créer auparavant un dépôt GitHub **vide** nommé `coppeliasim-pick-and-place` (sans README ni .gitignore pré-générés). Remplacer `TON_COMPTE` par le compte GitHub correct. **Vérifier les droits de redistribution des modèles CoppeliaSim avant de rendre le dépôt public.**
