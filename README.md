# Mon App JS - Application JavaScript pour TP Jenkins

Une application JavaScript simple avec une calculatrice, conçue pour démontrer l'intégration continue avec Jenkins.

## Fonctionnalités

- Calculatrice simple avec 4 opérations (addition, soustraction, multiplication, division)
- Interface utilisateur moderne et responsive
- Tests automatisés avec Jest
- Serveur de développement avec Express
- Endpoint de santé pour le monitoring

## Structure du projet

```
mon-app-js/
├── src/
│   ├── index.html      # Page principale
│   ├── app.js          # Logique de l'application
│   ├── utils.js        # Fonctions utilitaires
│   └── styles.css      # Styles CSS
├── tests/
│   └── app.test.js     # Tests unitaires
├── package.json        # Configuration npm
├── server.js           # Serveur de développement
└── README.md           # Documentation
```

## Installation

```bash
npm install
```

## Scripts disponibles

- `npm start` : Démarre le serveur de développement sur le port 3000
- `npm test` : Lance les tests unitaires avec Jest
- `npm run build` : Construit l'application pour la production
- `npm run clean` : Nettoie les fichiers générés

## Démarrage

```bash
npm start
```

L'application sera accessible à l'adresse : http://localhost:3000

## Tests

```bash
npm test
```

## Endpoints API

- `GET /` : Page principale de l'application
- `GET /health` : Endpoint de santé retournant le statut et la version

## Technologies utilisées

- HTML5
- CSS3
- JavaScript (ES6+)
- Node.js
- Express.js
- Jest (tests)
