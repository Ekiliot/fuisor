import { supabase } from '../config/supabase.js';

export const validateAuth = async (req, res, next) => {
  try {
    console.log('=== VALIDATE AUTH MIDDLEWARE ===');
    console.log('URL:', req.url);
    console.log('Method:', req.method);
    console.log('Headers:', req.headers);
    
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      console.log('❌ No authorization header');
      return res.status(401).json({ message: 'No authorization header' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error) {
      console.error('❌ Auth middleware error:', error);
      console.error('Token:', token.substring(0, 20) + '...');
      return res.status(401).json({ message: 'Invalid or expired token' });
    }

    console.log('Authenticated user:', { id: user.id, email: user.email });
    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Authentication failed' });
  }
};