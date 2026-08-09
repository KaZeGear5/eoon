import express from 'express';
import { WebSocketServer, WebSocket } from 'ws';
import { createServer } from 'http';

const app = express();
const PORT = process.env.PORT || 3000;

// Utilisation du middleware JSON
app.use(express.json());

const server = createServer(app);
const wss = new WebSocketServer({ server });

// Mémoire temporaire pour stocker les alertes en direct (sera remplacée par PostGIS plus tard)
let activeAlerts = [];

// Nettoie les alertes datant de plus de 2 heures
setInterval(() => {
  const twoHoursAgo = Date.now() - 2 * 60 * 60 * 1000;
  activeAlerts = activeAlerts.filter(alert => new Date(alert.timestamp).getTime() > twoHoursAgo);
  console.log(`[Nettoyage] Alertes actives conservées: ${activeAlerts.length}`);
}, 15 * 60 * 1000);

// Gestion des connexions WebSocket
wss.on('connection', (ws) => {
  console.log('⚡ Un conducteur s\'est connecté à EooN');

  // À la connexion, on envoie directement toutes les alertes actuelles au nouveau conducteur
  ws.send(JSON.stringify({
    type: 'INITIAL_ALERTS',
    data: activeAlerts
  }));

  ws.on('message', (message) => {
    try {
      const parsed = JSON.parse(message);

      // Réception d'un nouveau signalement
      if (parsed.type === 'NEW_ALERT') {
        const newAlert = {
          id: Date.now().toString(),
          alertType: parsed.data.alertType, // 'police', 'accident', 'hazard', 'traffic'
          latitude: parsed.data.latitude,
          longitude: parsed.data.longitude,
          timestamp: new Date().toISOString()
        };

        activeAlerts.push(newAlert);
        console.log(`⚠️ Nouvelle alerte ajoutée: ${newAlert.alertType} à [${newAlert.latitude}, ${newAlert.longitude}]`);

        // Diffusion immédiate (Broadcast) à TOUS les conducteurs connectés
        wss.clients.forEach((client) => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({
              type: 'BROADCAST_NEW_ALERT',
              data: newAlert
            }));
          }
        });
      }
    } catch (err) {
      console.error('Erreur lors du traitement du message WS:', err);
    }
  });

  ws.on('close', () => {
    console.log('❌ Conducteur déconnecté');
  });
});

// Route HTTP simple de santé du serveur
app.get('/health', (req, res) => {
  res.json({ status: 'ok', activeUsers: wss.clients.size, totalAlerts: activeAlerts.length });
});

server.listen(PORT, () => {
  console.log(`🚀 Serveur EooN Backend démarré sur http://localhost:${PORT}`);
});
