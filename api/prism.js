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
        // Get all servers - check both servers: and nametags:servers: keys
        const result = {};
        
        // Check regular servers: keys
        const serverKeys = await redis.keys('servers:*');
        for (const k of serverKeys) {
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
        
        // Check nametags:servers: keys for join data
        const nametagKeys = await redis.keys('nametags:servers:*');
        for (const k of nametagKeys) {
          const value = await redis.get(k);
          if (value) {
            const parts = k.replace('nametags:servers:', '').split(':');
            const placeId = parts[0];
            const jobId = parts[1];
            const userId = parts[2];
            if (placeId && jobId && userId) {
              if (!result[placeId]) result[placeId] = {};
              if (!result[placeId][jobId]) result[placeId][jobId] = {};
              result[placeId][jobId][userId] = value;
            }
          }
        }
        
        return res.status(200).json(result);
      } else if (pathParts.length >= 1) {
        const placeId = pathParts[0];
        const jobId = pathParts[1];
        
        // Check both key patterns
        const result = {};
        
        // Check regular servers: keys
        const serverPattern = pathParts.length === 1
          ? `servers:${placeId}:*`
          : pathParts.length === 2
            ? `servers:${placeId}:${jobId}:*`
            : key;
        const serverKeys = await redis.keys(serverPattern);
        for (const k of serverKeys) {
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
        
        // Check nametags:servers: keys
        if (pathParts.length === 1) {
          // Get all servers for this game from nametags
          const nametagPattern = `nametags:servers:${placeId}:*`;
          console.log('[API Debug] Searching for pattern:', nametagPattern);
          const nametagKeys = await redis.keys(nametagPattern);
          console.log('[API Debug] Found keys:', nametagKeys.length, nametagKeys);
          for (const k of nametagKeys) {
            const value = await redis.get(k);
            console.log('[API Debug] Key:', k, 'Value exists:', !!value);
            if (value) {
              const parts = k.replace('nametags:servers:', '').split(':');
              const pId = parts[0];
              const jId = parts[1];
              const uId = parts[2];
              if (!result[pId]) result[pId] = {};
              if (!result[pId][jId]) result[pId][jId] = {};
              result[pId][jId][uId] = value;
            }
          }
        } else if (pathParts.length === 2 && jobId) {
          // Get specific job from nametags
          const nametagPattern = `nametags:servers:${placeId}:${jobId}:*`;
          const nametagKeys = await redis.keys(nametagPattern);
          if (!result[placeId]) result[placeId] = {};
          if (!result[placeId][jobId]) result[placeId][jobId] = {};
          for (const k of nametagKeys) {
            const value = await redis.get(k);
            if (value) {
              const parts = k.replace('nametags:servers:', '').split(':');
              const uId = parts[2];
              result[placeId][jobId][uId] = value;
            }
          }
        }
        
        // If looking for specific user
        if (pathParts.length === 3) {
          const userId = pathParts[2];
          // Check nametags first
          const nametagValue = await redis.get(`nametags:servers:${placeId}:${jobId}:${userId}`);
          if (nametagValue) return res.status(200).json(nametagValue);
          // Fall back to regular key
          const serverValue = await redis.get(key);
          return res.status(200).json(serverValue || null);
        }
        
        return res.status(200).json(result);
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
