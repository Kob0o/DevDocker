# TP Docker — Déploiement et sécurisation d'une infrastructure applicative

## Contexte professionnel

Vous intervenez en tant qu'ingénieur DevOps pour une entreprise souhaitant moderniser l'hébergement d'une application de gestion interne.

Actuellement, les différents composants de l'application sont installés directement sur un serveur, ce qui complique leur maintenance, leur sécurisation et leurs mises à jour.

Votre mission consiste à concevoir et déployer une infrastructure conteneurisée avec Docker et Docker Compose, en respectant des exigences de disponibilité, de sécurité, de persistance et d'exploitation.

L'objectif n'est pas de développer une nouvelle application, mais de déployer et d'administrer une infrastructure fonctionnelle à partir d'images existantes.

## Architecture cible

L'infrastructure comprend trois services obligatoires :

- Nginx : point d'entrée HTTP unique.
- WordPress : application web à déployer et configurer.
- MariaDB : stockage des données de l'application.

Vous pouvez utiliser les images officielles disponibles sur [Docker Hub](https://hub.docker.com/).

## Partie 1 — Construction de l'infrastructure 

### Exercice 1 — Orchestration avec Docker Compose 

Créer un projet contenant un fichier `compose.yaml` permettant de déployer l'ensemble de l'infrastructure.

Contraintes techniques :

1. Déclarer les trois services nécessaires.
2. Utiliser des versions explicites pour les images Docker.
3. Définir une politique de redémarrage adaptée à chaque service.
4. Utiliser des variables d'environnement pour les paramètres configurables.
5. Permettre le lancement de l'infrastructure avec une seule commande.
6. Définir un nom de projet Compose cohérent.

Résultat attendu : l'ensemble des conteneurs démarre correctement et l'application est accessible depuis un navigateur.

### Exercice 2 — Isolation réseau 

Mettre en place une architecture reposant sur plusieurs réseaux Docker.

Contraintes :

1. Créer au minimum trois réseaux distincts.
2. Séparer le reverse proxy, l'application et la base de données.
3. Interdire toute exposition directe du port de MariaDB sur la machine hôte.
4. Permettre à WordPress de communiquer avec MariaDB.
5. Permettre à Nginx de communiquer avec WordPress.
6. Justifier la topologie réseau retenue.

Validation : démontrer que MariaDB n'est pas directement accessible depuis la machine hôte, mais reste joignable par l'application.

### Exercice 3 — Persistance des données 

Mettre en place une stratégie de persistance permettant de conserver les données en cas de suppression ou de recréation des conteneurs.

Contraintes :

1. Utiliser des volumes Docker nommés.
2. Garantir la persistance de la base de données.
3. Garantir la persistance des fichiers applicatifs.
4. Supprimer puis recréer les conteneurs sans perte de données.
5. Identifier les volumes et leurs points de montage.

Validation : créer un contenu dans WordPress, recréer entièrement les conteneurs, puis vérifier que ce contenu est toujours disponible.

### Exercice 4 — Reverse proxy Nginx 

Configurer Nginx comme unique point d'entrée de l'application.

Contraintes :

1. Exposer l'application sur le port `8080` de la machine hôte.
2. Rediriger les requêtes vers WordPress.
3. Utiliser le nom du service Docker pour joindre l'application.
4. Transmettre correctement les en-têtes HTTP nécessaires.
5. Empêcher l'accès direct à WordPress depuis la machine hôte.
6. Conserver la configuration Nginx dans un fichier indépendant du fichier Compose.

Validation : accéder à l'application depuis `http://localhost:8080`.

### Exercice 5 — Gestion du cycle de vie 

Mettre en place des mécanismes permettant de contrôler l'état des services.

Contraintes :

1. Définir des `healthchecks` pertinents pour au moins deux services.
2. Configurer les dépendances de démarrage en tenant compte de l'état de santé des services.
3. Vérifier le comportement de l'application lorsqu'un conteneur est arrêté manuellement.
4. Vérifier le comportement après le redémarrage d'un service.
5. Expliquer la différence entre un conteneur démarré et un service réellement opérationnel.

Validation : présenter l'état des services et démontrer le fonctionnement des contrôles de santé.

## Partie 2 — Sécurisation de l'infrastructure 

### Exercice 6 — Protection des informations sensibles 

Sécuriser les informations nécessaires au fonctionnement de l'application.

Contraintes :

1. Ne placer aucun mot de passe directement dans le fichier `compose.yaml`.
2. Utiliser un mécanisme adapté pour gérer les secrets.
3. Exclure les informations sensibles du suivi Git.
4. Fournir un fichier d'exemple permettant de comprendre les paramètres attendus.
5. Vérifier qu'aucun mot de passe n'est présent dans les fichiers versionnés.

Attention : les secrets Docker Compose sont montés sous forme de fichiers ; il faudra vérifier la compatibilité des images utilisées avec une configuration de type `_FILE`.

### Exercice 7 — Renforcement de la sécurité 

Appliquer plusieurs bonnes pratiques de sécurisation aux conteneurs.

Contraintes :

1. Identifier les services pouvant fonctionner sans privilèges root.
2. Limiter les capacités Linux lorsque cela est compatible avec le fonctionnement du service.
3. Étudier la possibilité d'utiliser un système de fichiers en lecture seule.
4. Limiter les ressources CPU et mémoire d'au moins deux services.
5. Vérifier qu'aucun conteneur ne fonctionne en mode privilégié.
6. Justifier les exceptions nécessaires au bon fonctionnement des images utilisées.

Validation : fournir une synthèse des mesures appliquées et expliquer les risques qu'elles permettent de réduire.

## Partie 3 — Exploitation et maintenance 

### Exercice 8 — Sauvegarde et restauration

Mettre en place une procédure permettant de sauvegarder puis de restaurer les données de l'application.

Contraintes :

1. Réaliser une sauvegarde logique de la base MariaDB.
2. Sauvegarder les fichiers applicatifs nécessaires à une restauration complète.
3. Stocker les sauvegardes dans un répertoire dédié sur la machine hôte.
4. Automatiser la sauvegarde avec un script.
5. Tester une restauration après suppression volontaire de données.
6. Documenter la procédure de restauration.

Validation : démontrer qu'une donnée supprimée peut être récupérée à partir d'une sauvegarde précédente.

### Exercice 9 — Supervision et diagnostic 
Mettre en place les outils et procédures nécessaires à l'exploitation de l'infrastructure.

Contraintes :

1. Consulter les journaux de chaque service.
2. Observer la consommation des ressources des conteneurs.
3. Identifier les causes d'un échec de connexion entre WordPress et MariaDB.
4. Vérifier la résolution DNS entre conteneurs.
5. Proposer une méthode permettant d'identifier un conteneur défaillant.
6. Rédiger une courte procédure de diagnostic.

Validation : simuler une panne, présenter la démarche suivie pour identifier son origine et rétablir le fonctionnement de l'application.

## Partie 4 — Défis bonus 

Bonus 1 — HTTPS 

Mettre en place HTTPS avec un certificat adapté à un environnement local et configurer la redirection HTTP vers HTTPS.

Bonus 2 — Profils Docker Compose 

Ajouter un outil d'administration de la base de données, activable uniquement avec un profil `admin`, sans l'exposer lors d'un déploiement classique.

Bonus 3 — Intégration continue 

Créer un pipeline GitHub Actions ou GitLab CI permettant de vérifier automatiquement la validité du fichier Compose et des configurations associées, et de réaliser des contrôles de sécurité élémentaires.

## Livrables attendus

Le travail devra être rendu sous la forme d'un dépôt Git contenant au minimum :

```
docker-advanced-tp/
├── compose.yaml
├── .env.example
├── .gitignore
├── nginx/
│   └── default.conf
├── secrets/
│   └── README.md
├── scripts/
│   ├── backup.sh
│   └── restore.sh
├── backups/
│   └── .gitkeep
├── docs/
│   └── architecture.md
└── README.md
```

La structure peut être adaptée si les choix techniques sont justifiés.

Le `README.md` devra présenter les prérequis, les commandes nécessaires au déploiement et à l'arrêt, les procédures de sauvegarde et de restauration, ainsi que les méthodes de vérification du bon fonctionnement.

Le dépôt ne doit contenir aucun secret réel ni aucune sauvegarde contenant des informations sensibles.

