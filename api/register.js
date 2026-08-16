// Register/update Prism user presence
// POST /api/register
// Body: { userId: number, username: string, displayName: string, placeId: number, jobId: string }

const { KV_REST_API_URL, KV_REST_API_TOKEN } = process.env;

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { userId, username, displayName, placeId, jobId } = req.body;

    if (!userId || !placeId || !jobId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Create user key with TTL (5 minutes)
    const userKey = `prism:user:${userId}`;
    const userData = {
      userId,
      username: username || 'Unknown',
      displayName: displayName || username || 'Unknown',
      placeId,
      jobId,
      lastSeen: Date.now()
    };

    // Store user data in Upstash KV
    const response = await fetch(`${KV_REST_API_URL}/set/${userKey}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${KV_REST_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        value: JSON.stringify(userData),
        ex: 300 // 5 minutes TTL
      })
    });

    if (!response.ok) {
      throw new Error('Failed to store user data');
    }

    // Also add to index for listing
    const indexKey = `prism:index:${userId}`;
    await fetch(`${KV_REST_API_URL}/set/${indexKey}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${KV_REST_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        value: '1',
        ex: 300
      })
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({ error: 'Registration failed' });
  }
}
