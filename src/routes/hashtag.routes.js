import express from 'express';
import { supabaseAdmin } from '../config/supabase.js';
import { validateAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

// Get hashtag info (name and posts count)
router.get('/:hashtag', validateAuth, async (req, res) => {
  try {
    const { hashtag } = req.params;
    const hashtagName = hashtag.toLowerCase();

    console.log('Getting hashtag info for:', hashtagName);

    // Get hashtag info
    const { data: hashtagData, error: hashtagError } = await supabaseAdmin
      .from('hashtags')
      .select('id, name, created_at')
      .eq('name', hashtagName)
      .single();

    if (hashtagError && hashtagError.code !== 'PGRST116') {
      console.error('Error getting hashtag:', hashtagError);
      return res.status(500).json({ error: 'Failed to get hashtag info' });
    }

    // Get posts count for this hashtag
    const { count: postsCount, error: countError } = await supabaseAdmin
      .from('post_hashtags')
      .select('*', { count: 'exact', head: true })
      .eq('hashtag_id', hashtagData?.id || '00000000-0000-0000-0000-000000000000');

    if (countError) {
      console.error('Error counting posts:', countError);
      return res.status(500).json({ error: 'Failed to count posts' });
    }

    // If hashtag doesn't exist, return empty info
    if (!hashtagData) {
      return res.json({
        name: hashtagName,
        posts_count: 0,
        created_at: null,
        exists: false,
      });
    }

    res.json({
      name: hashtagData.name,
      posts_count: postsCount || 0,
      created_at: hashtagData.created_at,
      exists: true,
    });
  } catch (error) {
    console.error('Error getting hashtag info:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
