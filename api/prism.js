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
    const pathname = url.pathname.replace('.json', '');
    
    // Route to appropriate handler based on path prefix
    if (pathname.startsWith('/api/prism/nametags/')) {
      return await handleNametags(req, res, pathname);
    } else if (pathname.startsWith('/api/prism/servers/')) {
      return await handleServers(req, res, pathname);
    } else {
      return res.status(404).json({ error: 'Unknown endpoint. Use /api/prism/nametags/... or /api/prism/servers/...' });
    }
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: error.message });
  }
}

// ========== NAMETAGS HANDLER ==========
async function handleNametags(req, res, pathname) {
  // Parse path: /api/prism/nametags/servers/placeId/jobId/userId
  const pathParts = pathname
    .replace('/api/prism/nametags/', '')
    .split('/')
    .filter(Boolean);
  
  // Key format: nametags:servers:placeId:jobId (base), nametags:servers:placeId:jobId:userId (individual)
  const serverKey = pathParts.length >= 3 
    ? `nametags:servers:${pathParts[1]}:${pathParts[2]}`
    : 'nametags:root';

  switch (req.method) {
    case 'GET': {
      if (pathParts.length === 0) {
        // Get all nametag servers
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
        // Delete all users in this server
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
}

// ========== SERVERS HANDLER ==========
async function handleServers(req, res, pathname) {
  // Parse path: /api/prism/servers/placeId/jobId/userId
  const pathParts = pathname
    .replace('/api/prism/servers/', '')
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
}
