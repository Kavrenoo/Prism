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
    // Parse path: /api/servers/placeId/jobId/userId
    const pathParts = url.pathname
      .replace('/api/servers/', '')
      .replace('.json', '')
      .split('/')
      .filter(Boolean);
    
    const key = pathParts.length > 0 ? `servers:${pathParts.join(':')}` : 'servers:root';

    switch (req.method) {
      case 'GET': {
        if (pathParts.length === 0) {
          // Get all servers across all games
          const keys = await redis.keys('servers:*');
          const result = {};
          
          for (const k of keys) {
            const value = await redis.get(k);
            if (value) {
              const parts = k.replace('servers:', '').split(':');
              let current = result;
              for (let i = 0; i < parts.length - 1; i++) {
                if (!current[parts[i]]) current[parts[i]] = {};
                current = current[parts[i]];
              }
              current[parts[parts.length - 1]] = value;
            }
          }
          return res.status(200).json(result);
        } else if (pathParts.length >= 1) {
          // Get specific game, server, or user
          const pattern = pathParts.length === 1
            ? `servers:${pathParts[0]}:*`
            : pathParts.length === 2
              ? `servers:${pathParts[0]}:${pathParts[1]}:*`
              : key;
          
          if (pathParts.length === 3) {
            // Single user
            const value = await redis.get(key);
            return res.status(200).json(value || null);
          } else {
            // Nested data
            const keys = await redis.keys(pattern);
            const result = {};
            for (const k of keys) {
              const value = await redis.get(k);
              if (value) {
                const parts = k.replace('servers:', '').split(':');
                let current = result;
                for (let i = 0; i < parts.length - 1; i++) {
                  if (!current[parts[i]]) current[parts[i]] = {};
                  current = current[parts[i]];
                }
                current[parts[parts.length - 1]] = value;
              }
            }
            return res.status(200).json(result);
          }
        }
        break;
      }

      case 'PUT': {
        const body = req.body || {};
        // Set with 30 second TTL
        await redis.set(key, body, { ex: 30 });
        return res.status(200).json(body);
      }

      case 'DELETE': {
        await redis.del(key);
        return res.status(200).json(null);
      }

      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: error.message });
  }
}
