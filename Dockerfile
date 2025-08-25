# Dockerfile pour mon-app-js
FROM node:18-alpine AS builder

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production && npm cache clean --force

# Copier le code source
COPY . .

# Construire l'application
RUN npm run build

# Stage de production
FROM node:18-alpine AS production

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Définir le répertoire de travail
WORKDIR /app

# Copier les dépendances de production depuis le builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Copier les fichiers construits et le serveur
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.js ./

# Changer la propriété des fichiers
RUN chown -R nodejs:nodejs /app

# Passer à l'utilisateur non-root
USER nodejs

# Exposer le port
EXPOSE 3000

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Commande de démarrage
CMD ["node", "server.js"]
