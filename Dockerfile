# Image de base Node.js 18 Alpine
FROM node:18-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Copier le code source
COPY . .

# Exposer le port 3000
EXPOSE 3000

# Commande par défaut
CMD ["npm", "start"]
