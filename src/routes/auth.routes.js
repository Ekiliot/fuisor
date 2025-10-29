import express from 'express';
import { supabase, supabaseAdmin } from '../config/supabase.js';
import { validateAuth } from '../middleware/auth.middleware.js';
import { validateSignup, validateLogin } from '../middleware/validation.middleware.js';

const router = express.Router();

// Sign up
router.post('/signup', validateSignup, async (req, res) => {
  try {
    const { email, password, username, name } = req.body;
    
    const { data: existingUser, error: searchError } = await supabase
      .from('profiles')
      .select('username')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({ message: 'Username already taken' });
    }

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) throw error;

    // Create profile using admin client to bypass RLS
    if (!supabaseAdmin) {
      throw new Error('Service role key not configured');
    }

    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert([
        {
          id: data.user.id,
          username,
          name,
          email,
        },
      ]);

    if (profileError) {
      console.error('Profile creation error:', profileError);
      throw profileError;
    }

    console.log('Profile created successfully for user:', data.user.id);
    res.status(201).json({ message: 'User created successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Login
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email_or_username, password } = req.body;

    // Determine if input is email or username
    const isEmail = email_or_username.includes('@');
    
    let userEmail;
    
    if (isEmail) {
      // Input is email, use directly
      userEmail = email_or_username;
    } else {
      // Input is username, find corresponding email
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('email')
        .eq('username', email_or_username)
        .single();

      if (profileError || !profile) {
        return res.status(401).json({ error: 'Invalid username or password' });
      }
      
      userEmail = profile.email;
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email: userEmail,
      password,
    });

    if (error) throw error;

    // Get user profile for additional info
    const { data: userProfile } = await supabase
      .from('profiles')
      .select('username, name, avatar_url, bio')
      .eq('id', data.user.id)
      .single();

    res.json({ 
      user: data.user, 
      session: data.session,
      profile: userProfile
    });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

// Logout
router.post('/logout', validateAuth, async (req, res) => {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;