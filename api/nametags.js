import { Redis } from "@upstash/redis";

const redis = Redis.fromEnv();

export default async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    // Parse path: /api/nametags/servers/placeId/jobId or /api/nametags/servers/placeId/jobId/userId
    const pathParts = url.pathname
      .replace('/api/nametags/', '')
      .replace('.json', '')
      .split('/')
      .filter(Boolean);
    
    // Key format: nametags:servers:placeId:jobId (stores all players in server)
    const serverKey = pathParts.length >= 3 
      ? `nametags:servers:${pathParts[1]}:${pathParts[2]}`
      : 'nametags:root';

    switch (req.method) {
      case 'GET': {
        if (pathParts.length === 0) {
          // Get all servers
          const keys = await redis.keys('nametags:servers:*');
          const result = {};
          for (const k of keys) {
            const value = await redis.get(k);
            if (value) {
              const parts = k.replace('nametags:servers:', '').split(':');
              const placeId = parts[0];
              const jobId = parts[1];
              if (!result[placeId]) result[placeId] = {};
              result[placeId][jobId] = value;
            }
          }
          return res.status(200).json(result);
        } else if (pathParts.length >= 3) {
          // Get all players in a specific server
          const serverData = await redis.get(serverKey);
          return res.status(200).json(serverData || {});
        }
        break;
      }

      case 'PUT': {
        const body = req.body || {};
        const userId = pathParts[3]; // 4th part is userId
        
        if (!userId) {
          return res.status(400).json({ error: 'UserId required' });
        }
        
        // Get existing server data or create new
        let serverData = await redis.get(serverKey) || {};
        
        // Add/update this user
        serverData[userId] = body;
        
        // Save back with 30 second TTL (auto-cleanup if no updates)
        await redis.set(serverKey, serverData, { ex: 30 });
        
        return res.status(200).json(body);
      }

      case 'DELETE': {
        if (pathParts.length >= 4) {
          // Remove specific user from server
          let serverData = await redis.get(serverKey) || {};
          delete serverData[pathParts[3]];
          await redis.set(serverKey, serverData, { ex: 30 });
          return res.status(200).json(null);
        } else {
          // Delete entire server entry
          await redis.del(serverKey);
          return res.status(200).json(null);
        }
      }

      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: error.message });
  }
}
