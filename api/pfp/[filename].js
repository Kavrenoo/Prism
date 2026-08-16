import fs from 'fs';
import path from 'path';

export default async function handler(req, res) {
  const { filename } = req.query;
  
  if (!filename) {
    return res.status(400).json({ error: 'Filename required' });
  }

  // Security: Only allow serving from the profile pictures directory
  const profilePicturesDir = path.join(process.cwd(), 'nametag profile pictures');
  const filePath = path.join(profilePicturesDir, filename);

  // Prevent directory traversal
  const normalizedPath = path.normalize(filePath);
  if (!normalizedPath.startsWith(path.normalize(profilePicturesDir))) {
    return res.status(403).json({ error: 'Access denied' });
  }

  try {
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Get file extension for content type
    const ext = path.extname(filename).toLowerCase();
    const contentTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
    };

    const contentType = contentTypes[ext] || 'application/octet-stream';

    // Read and serve the file
    const fileBuffer = fs.readFileSync(filePath);
    
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year
    return res.status(200).send(fileBuffer);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
}
