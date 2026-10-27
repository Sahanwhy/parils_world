require('dotenv').config();
const dns = require('dns');

// Fix for Windows DNS resolution with mongodb+srv://
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {
  console.warn('DNS server override notice:', e.message);
}

const express = require('express');
const cors = require('cors');
const { MongoClient, ServerApiVersion } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ──────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── MongoDB Connection ──────────────────────────────────────────────────────
const client = new MongoClient(process.env.MONGODB_URI, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  },
  connectTimeoutMS: 8000,
  serverSelectionTimeoutMS: 8000,
});

let db = null;
let isConnected = false;

async function connectDB() {
  try {
    await client.connect();
    db = client.db('paril_world');
    isConnected = true;
    console.log('✅ Connected to MongoDB Atlas — database: paril_world');
  } catch (err) {
    isConnected = false;
    console.error('⚠️ MongoDB Connection Issue:', err.message);
    if (err.message.includes('SSL') || err.message.includes('alert')) {
      console.error('💡 Tip: Ensure your IP is whitelisted in MongoDB Atlas -> Network Access -> Add IP Address -> Allow Access from Anywhere (0.0.0.0/0).');
    }
  }
}

// ── Collections Helper ───────────────────────────────────────────────────────
const leaderboard = () => {
  if (!db) throw new Error('Database not connected yet');
  return db.collection('leaderboard');
};

const players = () => {
  if (!db) throw new Error('Database not connected yet');
  return db.collection('players');
};

// ── Routes ───────────────────────────────────────────────────────────────────

// GET /health — simple ping
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    databaseConnected: isConnected,
    timestamp: new Date().toISOString(),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD
// ─────────────────────────────────────────────────────────────────────────────

// GET /leaderboard — top 20 scores
app.get('/leaderboard', async (req, res) => {
  try {
    if (!isConnected || !db) {
      await connectDB();
    }
    if (!isConnected || !db) {
      return res.status(503).json({ error: 'Database connecting, please retry in a moment.' });
    }

    const scores = await leaderboard()
      .find({})
      .sort({ score: -1 })
      .limit(20)
      .toArray();
    res.json(scores);
  } catch (err) {
    console.error('GET /leaderboard error:', err);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

// POST /leaderboard — submit a new score
// Body: { playerName, role, score, iceCreamCount }
app.post('/leaderboard', async (req, res) => {
  try {
    const { playerName, role, score, iceCreamCount } = req.body;

    if (!playerName || score === undefined) {
      return res.status(400).json({ error: 'playerName and score are required' });
    }

    if (!isConnected || !db) {
      await connectDB();
    }
    if (!isConnected || !db) {
      return res.status(503).json({ error: 'Database connecting, please retry in a moment.' });
    }

    const entry = {
      playerName: String(playerName).trim(),
      role: role || 'unknown',
      score: Number(score),
      iceCreamCount: Number(iceCreamCount) || 0,
      submittedAt: new Date(),
    };

    const result = await leaderboard().insertOne(entry);
    res.status(201).json({ insertedId: result.insertedId, entry });
  } catch (err) {
    console.error('POST /leaderboard error:', err);
    res.status(500).json({ error: 'Failed to save score' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PLAYERS
// ─────────────────────────────────────────────────────────────────────────────

// POST /players — register/update a player
// Body: { name, role, deviceId }
app.post('/players', async (req, res) => {
  try {
    const { name, role, deviceId } = req.body;

    if (!name || !role) {
      return res.status(400).json({ error: 'name and role are required' });
    }

    if (!isConnected || !db) {
      await connectDB();
    }
    if (!isConnected || !db) {
      return res.status(503).json({ error: 'Database connecting, please retry in a moment.' });
    }

    const player = {
      name: String(name).trim(),
      role: String(role),
      deviceId: deviceId || null,
      registeredAt: new Date(),
      lastSeenAt: new Date(),
    };

    if (deviceId) {
      await players().updateOne(
        { deviceId },
        { $set: player },
        { upsert: true }
      );
    } else {
      await players().insertOne(player);
    }

    res.status(201).json({ player });
  } catch (err) {
    console.error('POST /players error:', err);
    res.status(500).json({ error: 'Failed to save player' });
  }
});

// GET /players — list all registered players
app.get('/players', async (req, res) => {
  try {
    if (!isConnected || !db) {
      await connectDB();
    }
    if (!isConnected || !db) {
      return res.status(503).json({ error: 'Database connecting, please retry in a moment.' });
    }

    const allPlayers = await players()
      .find({})
      .sort({ registeredAt: -1 })
      .toArray();
    res.json(allPlayers);
  } catch (err) {
    console.error('GET /players error:', err);
    res.status(500).json({ error: 'Failed to fetch players' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Start Server
// ─────────────────────────────────────────────────────────────────────────────
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Paril World API running on http://0.0.0.0:${PORT}`);
  console.log(`   Leaderboard : GET/POST http://localhost:${PORT}/leaderboard`);
  console.log(`   Players     : GET/POST http://localhost:${PORT}/players`);
  // Connect to DB in background
  connectDB();
});
