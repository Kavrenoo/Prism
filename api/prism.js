import { Redis } from "@upstash/redis";
import crypto from 'crypto';

const redis = Redis.fromEnv();
const ANTI_BYPASS_TOKEN = 'b7c7c3a5dd0580495d9e185e973791366fa1597cac1ed6ae5a64c15a1646776e';

// ========== WEEKLY KEY SYSTEM ==========
function getCurrentWeekKey() {
  const now = new Date();
  const year = now.getFullYear();
  const week = getISOWeek(now);
  const seed = `prism-key-${year}-${week}`;
  return crypto.createHash('sha256').update(seed).digest('hex').substring(0, 32);
}

function getISOWeek(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
}

async function verifyWeeklyKey(providedKey) {
  const currentKey = getCurrentWeekKey();
  return providedKey === currentKey;
}

// ========== ANTI-BYPASS VERIFICATION ==========
async function verifyAntiBypass(req) {
  const referer = req.headers.referer || req.headers.referrer || '';
  const userAgent = req.headers['user-agent'] || '';
  
  // Check if request has anti-bypass token in headers or query
  const headerToken = req.headers['x-anti-bypass-token'] || req.headers['anti-bypass-token'];
  const queryToken = req.query?.token || req.query?.anti_bypass_token;
  const providedToken = headerToken || queryToken;
  
  // Verify the token matches
  if (providedToken !== ANTI_BYPASS_TOKEN) {
    return false;
  }
  
  // Additional checks based on Linkvertise documentation
  // Check if coming from a valid source (not direct access from Discord/Telegram etc)
  const validReferers = [
    'linkvertise.com',
    'link-to.net',
    'direct-link.net',
    'link-center.net'
  ];
  
  // If referer exists, check if it's from a valid source
  if (referer) {
    const isValidReferer = validReferers.some(domain => referer.includes(domain));
    if (!isValidReferer) {
      return false;
    }
  }
  
  return true;
}

export default async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-API-Key, X-Anti-Bypass-Token');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const pathname = url.pathname.replace('.json', '');
    
    // Route to appropriate handler based on path prefix
    if (pathname === '/api/prism/key') {
      // Special endpoint to get current weekly key (only requires anti-bypass)
      if (!(await verifyAntiBypass(req))) {
        return res.status(403).json({ 
          error: 'Anti-bypass verification failed',
          message: 'Please access this endpoint through the official Linkvertise link'
        });
      }
      const currentKey = getCurrentWeekKey();
      const now = new Date();
      const year = now.getFullYear();
      const week = getISOWeek(now);
      return res.status(200).json({ 
        key: currentKey,
        week: week,
        year: year,
        expiresAt: new Date(now.getTime() + (7 - now.getDay() + 1) * 24 * 60 * 60 * 1000).toISOString()
      });
    } else if (pathname.startsWith('/api/prism/nametags/') || pathname.startsWith('/api/prism/servers/')) {
      // Verify weekly key and anti-bypass for protected endpoints
      // Get API key from header or query
      const apiKey = req.headers['x-api-key'] || req.query?.key || req.query?.api_key;
      
      // Verify weekly key
      if (!apiKey || !(await verifyWeeklyKey(apiKey))) {
        return res.status(401).json({ 
          error: 'Invalid or expired API key', 
          message: 'Please use the current weekly key'
        });
      }
      
      // Verify anti-bypass
      if (!(await verifyAntiBypass(req))) {
        return res.status(403).json({ 
          error: 'Anti-bypass verification failed',
          message: 'Please access this endpoint through the official Linkvertise link'
        });
      }
      
      if (pathname.startsWith('/api/prism/nametags/')) {
        return await handleNametags(req, res, pathname);
      } else if (pathname.startsWith('/api/prism/servers/')) {
        return await handleServers(req, res, pathname);
      }
    } else {
      return res.status(404).json({ error: 'Unknown endpoint. Use /api/prism/key, /api/prism/nametags/... or /api/prism/servers/...' });
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
