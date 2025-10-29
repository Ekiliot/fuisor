import express from 'express';
import { supabase, supabaseAdmin } from '../config/supabase.js';
import { validateAuth } from '../middleware/auth.middleware.js';
import { validateProfileUpdate, validateUUID } from '../middleware/validation.middleware.js';
import multer from 'multer';

const router = express.Router();
const upload = multer();

// Get current user profile
router.get('/profile', validateAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    console.log('Get current user profile for:', userId);

    // Get user profile
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      console.log('Profile error:', profileError);
      return res.status(404).json({ message: 'User profile not found' });
    }

    // Get followers count
    const { count: followersCount, error: followersError } = await supabaseAdmin
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('following_id', userId);

    if (followersError) throw followersError;

    // Get following count
    const { count: followingCount, error: followingError } = await supabaseAdmin
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', userId);

    if (followingError) throw followingError;

    // Get posts count
    const { count: postsCount, error: postsError } = await supabaseAdmin
      .from('posts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    if (postsError) throw postsError;

    res.json({
      ...profile,
      followers_count: followersCount || 0,
      following_count: followingCount || 0,
      posts_count: postsCount || 0,
    });
  } catch (error) {
    console.error('Error getting current user profile:', error);
    res.status(500).json({ error: 'Failed to get user profile' });
  }
});

// Get user profile by ID
router.get('/:id', validateUUID, async (req, res) => {
  try {
    const { id } = req.params;

    // Get user profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (profileError || !profile) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get followers count
    const { count: followersCount, error: followersError } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('following_id', id);

    if (followersError) throw followersError;

    // Get following count
    const { count: followingCount, error: followingError } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', id);

    if (followingError) throw followingError;

    // Get posts count
    const { count: postsCount, error: postsError } = await supabase
      .from('posts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', id);

    if (postsError) throw postsError;

    res.json({
      ...profile,
      followers_count: followersCount || 0,
      following_count: followingCount || 0,
      posts_count: postsCount || 0
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user profile
router.put('/profile', validateAuth, upload.single('avatar'), validateProfileUpdate, async (req, res) => {
  try {
    const { username, name, bio } = req.body;
    const avatar = req.file;
    let avatarUrl = null;

    console.log('Update profile request:', { username, name, bio, hasAvatar: !!avatar });

    if (avatar) {
      // Сначала получаем текущий аватар пользователя для удаления
      const { data: currentProfile } = await supabaseAdmin
        .from('profiles')
        .select('avatar_url')
        .eq('id', req.user.id)
        .single();

      // Upload avatar to Supabase Storage
      console.log('Avatar file info:', {
        originalname: avatar.originalname,
        mimetype: avatar.mimetype,
        size: avatar.size
      });

      // Определяем расширение файла
      let fileExt = 'jpg'; // По умолчанию
      
      if (avatar.originalname && avatar.originalname.includes('.')) {
        fileExt = avatar.originalname.split('.').pop().toLowerCase();
      } else if (avatar.mimetype) {
        // Определяем расширение по MIME типу
        const mimeToExt = {
          'image/jpeg': 'jpg',
          'image/jpg': 'jpg',
          'image/png': 'png',
          'image/gif': 'gif',
          'image/webp': 'webp'
        };
        fileExt = mimeToExt[avatar.mimetype] || 'jpg';
      }

      // Проверяем, что расширение валидное
      const validExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!validExts.includes(fileExt)) {
        fileExt = 'jpg';
      }

      const fileName = `${Math.random().toString(36).substring(7)}.${fileExt}`;
      console.log('Generated filename:', fileName);

      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(fileName, avatar.buffer);

      if (uploadError) {
        console.error('Avatar upload error:', uploadError);
        throw uploadError;
      }

      // Get public URL for the uploaded avatar
      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(fileName);

      avatarUrl = publicUrl;
      console.log('Avatar uploaded successfully:', avatarUrl);

      // Удаляем старый аватар, если он существует
      if (currentProfile?.avatar_url) {
        try {
          // Извлекаем имя файла из URL
          const oldFileName = currentProfile.avatar_url.split('/').pop();
          console.log('Deleting old avatar:', oldFileName);
          
          const { error: deleteError } = await supabaseAdmin.storage
            .from('avatars')
            .remove([oldFileName]);
          
          if (deleteError) {
            console.error('Error deleting old avatar:', deleteError);
            // Не прерываем выполнение, так как новый аватар уже загружен
          } else {
            console.log('Old avatar deleted successfully');
          }
        } catch (deleteErr) {
          console.error('Error deleting old avatar:', deleteErr);
          // Не прерываем выполнение, так как новый аватар уже загружен
        }
      }
    }

    const updates = {
      ...(username && { username }),
      ...(name && { name }),
      ...(bio && { bio }),
      ...(avatarUrl && { avatar_url: avatarUrl }),
      updated_at: new Date()
    };

    console.log('Updates to apply:', updates);
    console.log('User ID:', req.user.id);

    // Сначала проверим, существует ли пользователь
    const { data: existingUser, error: checkError } = await supabaseAdmin
      .from('profiles')
      .select('id, username, name')
      .eq('id', req.user.id)
      .single();

    if (checkError) {
      console.error('User check error:', checkError);
      throw new Error(`User not found: ${checkError.message}`);
    }

    console.log('Existing user:', existingUser);

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update(updates)
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error:', error);
      throw error;
    }

    console.log('Profile updated successfully:', data);

    // Get updated profile with counts
    const { data: updatedProfile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .single();

    if (profileError) throw profileError;

    // Get followers count
    const { count: followersCount, error: followersError } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('following_id', req.user.id);

    // Get following count
    const { count: followingCount, error: followingError } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', req.user.id);

    // Get posts count
    const { count: postsCount, error: postsError } = await supabase
      .from('posts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', req.user.id);

    res.json({
      ...updatedProfile,
      followers_count: followersCount || 0,
      following_count: followingCount || 0,
      posts_count: postsCount || 0
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Follow user
router.post('/follow/:id', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const followerId = req.user.id;

    if (id === followerId) {
      return res.status(400).json({ message: 'Cannot follow yourself' });
    }

    const { error } = await supabase
      .from('follows')
      .insert([
        { follower_id: followerId, following_id: id }
      ]);

    if (error) throw error;

    res.json({ message: 'Successfully followed user' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Unfollow user
router.post('/unfollow/:id', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const followerId = req.user.id;

    const { error } = await supabase
      .from('follows')
      .delete()
      .eq('follower_id', followerId)
      .eq('following_id', id);

    if (error) throw error;

    res.json({ message: 'Successfully unfollowed user' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user posts
router.get('/:id/posts', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    // Check if user exists
    const { data: user, error: userError } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', id)
      .single();

    if (userError || !user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const { data, error, count } = await supabaseAdmin
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        likes(count)
      `, { count: 'exact' })
      .eq('user_id', id)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;

    // Get user's likes for all posts (if user is authenticated)
    let likedPostIds = new Set();
    const currentUserId = req.user?.id;
    if (currentUserId) {
      const postIds = data.map(post => post.id);
      const { data: userLikes, error: likesError } = await supabaseAdmin
        .from('likes')
        .select('post_id')
        .eq('user_id', currentUserId)
        .in('post_id', postIds);

      if (!likesError && userLikes) {
        likedPostIds = new Set(userLikes.map(like => like.post_id));
      }
    }

    // Transform data to include likes count and is_liked status
    const postsWithLikes = data.map(post => ({
      ...post,
      likes_count: post.likes?.[0]?.count || 0,
      is_liked: likedPostIds.has(post.id),
      likes: undefined // Remove the likes array from response
    }));

    res.json({
      posts: postsWithLikes,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get saved posts
router.get('/me/saved', validateAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + parseInt(limit) - 1;

    // Get saved posts with post details
    const { data: savedPosts, error: savedError } = await supabaseAdmin
      .from('saved_posts')
      .select(`
        post_id,
        created_at,
        posts:post_id (
          id,
          user_id,
          caption,
          media_url,
          media_type,
          created_at,
          updated_at,
          profiles:user_id (
            id,
            username,
            name,
            avatar_url
          )
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (savedError) throw savedError;

    // Get counts for each post
    const postsWithCounts = await Promise.all(
      (savedPosts || []).map(async (savedPost) => {
        const post = savedPost.posts;
        if (!post) return null;

        // Get likes count
        const { count: likesCount } = await supabaseAdmin
          .from('likes')
          .select('*', { count: 'exact', head: true })
          .eq('post_id', post.id);

        // Get comments count
        const { count: commentsCount } = await supabaseAdmin
          .from('comments')
          .select('*', { count: 'exact', head: true })
          .eq('post_id', post.id)
          .is('parent_comment_id', null);

        // Check if current user liked this post
        const { data: userLike } = await supabaseAdmin
          .from('likes')
          .select('id')
          .eq('post_id', post.id)
          .eq('user_id', userId)
          .single();

        return {
          ...post,
          likesCount: likesCount || 0,
          commentsCount: commentsCount || 0,
          isLiked: !!userLike,
          isSaved: true,
        };
      })
    );

    // Filter out nulls and get total count
    const filteredPosts = postsWithCounts.filter(p => p !== null);

    const { count } = await supabaseAdmin
      .from('saved_posts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    res.json({
      posts: filteredPosts,
      page: parseInt(page),
      limit: parseInt(limit),
      total: count || 0,
      totalPages: Math.ceil((count || 0) / limit)
    });
  } catch (error) {
    console.error('Error getting saved posts:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;