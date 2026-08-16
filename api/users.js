// Fetch all active Prism users
// GET /api/users

const { KV_REST_API_URL, KV_REST_API_TOKEN } = process.env;

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Get all keys with prefix "prism:user:"
    const keysResponse = await fetch(`${KV_REST_API_URL}/keys/prism:user:*`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${KV_REST_API_TOKEN}`
      }
    });

    if (!keysResponse.ok) {
      throw new Error('Failed to fetch user keys');
    }

    const keysData = await keysResponse.json();
    const keys = keysData.result || [];

    if (keys.length === 0) {
      return res.status(200).json({ users: [] });
    }

    // Fetch all user data in parallel
    const userPromises = keys.map(async (key) => {
      const valueResponse = await fetch(`${KV_REST_API_URL}/get/${key}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${KV_REST_API_TOKEN}`
        }
      });

      if (!valueResponse.ok) {
        return null;
      }

      const valueData = await valueResponse.json();
      const userData = JSON.parse(valueData.result);

      return {
        userId: userData.userId,
        username: userData.username,
        displayName: userData.displayName,
        placeId: userData.placeId,
        jobId: userData.jobId,
        lastSeen: userData.lastSeen
      };
    });

    const users = (await Promise.all(userPromises)).filter(user => user !== null);

    return res.status(200).json({ users });
  } catch (error) {
    console.error('Fetch users error:', error);
    return res.status(500).json({ error: 'Failed to fetch users' });
  }
}
