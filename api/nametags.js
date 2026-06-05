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
              const userId = parts[2];
              if (!result[placeId]) result[placeId] = {};
              if (!result[placeId][jobId]) result[placeId][jobId] = {};
              result[placeId][jobId][userId] = value;
            }
          }
          return res.status(200).json(result);
        } else if (pathParts.length >= 3) {
          // Get all players in a specific server (aggregate individual keys)
          const pattern = `${serverKey}:*`;
          const keys = await redis.keys(pattern);
          const result = {};
          for (const k of keys) {
            const value = await redis.get(k);
            if (value) {
              // Extract userId from key (nametags:servers:place:job:userId)
              const parts = k.split(':');
              const userId = parts[parts.length - 1];
              result[userId] = value;
            }
          }
          return res.status(200).json(result);
        }
        break;
      }

      case 'PUT': {
        const body = req.body || {};
        const userId = pathParts[3]; // 4th part is userId
        
        if (!userId) {
          return res.status(400).json({ error: 'UserId required' });
        }
        
        // Store each user individually with their own TTL
        // Key: nametags:servers:placeId:jobId:userId
        const userKey = `${serverKey}:${userId}`;
        await redis.set(userKey, body, { ex: 30 });
        
        return res.status(200).json(body);
      }

      case 'DELETE': {
        if (pathParts.length >= 4) {
          // Remove specific user
          const userKey = `${serverKey}:${pathParts[3]}`;
          await redis.del(userKey);
          return res.status(200).json(null);
        } else {
          // Delete all users in this server (pattern delete)
          const keys = await redis.keys(`${serverKey}:*`);
          for (const k of keys) {
            await redis.del(k);
          }
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
