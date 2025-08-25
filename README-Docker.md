# Conteneurisation avec Docker

Ce projet a été conteneurisé avec Docker et Docker Compose pour faciliter le déploiement et le développement.

## Prérequis

- Docker (version 20.10+)
- Docker Compose (version 2.0+)

## Structure des fichiers Docker

- `Dockerfile` : Image de production optimisée avec multi-stage build
- `Dockerfile.dev` : Image de développement pour le hot-reload
- `docker-compose.yml` : Configuration pour développement et production
- `docker-compose.prod.yml` : Configuration optimisée pour la production
- `.dockerignore` : Fichiers exclus du contexte Docker

## Utilisation

### Développement

```bash
# Démarrer l'application en mode développement
docker-compose --profile dev up

# Ou utiliser le Dockerfile de développement
docker build -f Dockerfile.dev -t mon-app-js:dev .
docker run -p 3001:3000 -v $(pwd):/app mon-app-js:dev
```

### Production

```bash
# Construire et démarrer l'application
docker-compose up -d

# Utiliser la configuration de production
docker-compose -f docker-compose.prod.yml up -d

# Avec Nginx (reverse proxy)
docker-compose -f docker-compose.prod.yml --profile nginx up -d
```

### Commandes utiles

```bash
# Voir les logs
docker-compose logs -f app

# Arrêter l'application
docker-compose down

# Reconstruire l'image
docker-compose build --no-cache

# Nettoyer les images
docker system prune -f

# Vérifier la santé de l'application
curl http://localhost:3000/health
```

## Configuration Jenkins

Le pipeline Jenkins a été adapté pour utiliser Docker :

1. **Build** : Construction de l'image Docker
2. **Tests** : Exécution des tests dans un conteneur
3. **Déploiement** : Utilisation de Docker Compose pour le déploiement
4. **Health Check** : Vérification de la santé de l'application

## Variables d'environnement

- `NODE_ENV` : Environnement (development/production)
- `PORT` : Port d'écoute (défaut: 3000)

## Sécurité

- Utilisation d'un utilisateur non-root dans le conteneur
- Health checks intégrés
- Limitation des ressources
- Scan de sécurité des dépendances

## Monitoring

L'application expose un endpoint de santé :
- URL : `http://localhost:3000/health`
- Format : JSON avec status, timestamp et version

## Troubleshooting

### Problèmes courants

1. **Port déjà utilisé** : Changez le port dans docker-compose.yml
2. **Permissions** : Vérifiez les permissions sur les volumes
3. **Ressources** : Ajustez les limites dans docker-compose.prod.yml

### Logs

```bash
# Logs de l'application
docker logs mon-app-js

# Logs de tous les services
docker-compose logs

# Logs en temps réel
docker-compose logs -f
```
