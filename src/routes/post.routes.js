import express from 'express';
import { supabase, supabaseAdmin } from '../config/supabase.js';
import { validateAuth } from '../middleware/auth.middleware.js';
import { validatePost, validatePostUpdate, validateComment, validateUUID, validateCommentId } from '../middleware/validation.middleware.js';
import { createNotification } from './notification.routes.js';
import multer from 'multer';

const router = express.Router();
const upload = multer();

// Логирование всех POST запросов к /posts
router.use('/', (req, res, next) => {
  if (req.method === 'POST') {
    console.log('=== POST REQUEST TO /posts ===');
    console.log('Method:', req.method);
    console.log('URL:', req.url);
    console.log('Headers:', req.headers);
    console.log('Body keys:', Object.keys(req.body || {}));
  }
  next();
});

// Get all posts (with pagination)
router.get('/', validateAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const userId = req.user.id;

    const { data, error, count } = await supabaseAdmin
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        likes(count)
      `, { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;

    // Get user's likes for all posts
    const postIds = data.map(post => post.id);
    const { data: userLikes, error: likesError } = await supabaseAdmin
      .from('likes')
      .select('post_id')
      .eq('user_id', userId)
      .in('post_id', postIds);

    if (likesError) throw likesError;

    const likedPostIds = new Set(userLikes.map(like => like.post_id));

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

// Create post
router.post('/', validateAuth, upload.single('media'), validatePost, async (req, res) => {
  try {
    console.log('=== POST CREATION REQUEST ===');
    console.log('User ID:', req.user.id);
    console.log('User email:', req.user.email);
    console.log('Request body:', req.body);
    console.log('Media file:', req.file ? {
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size
    } : 'No file');
    
    const { caption, media_type, mentions, hashtags } = req.body;
    const media = req.file;

    if (!media) {
      console.log('❌ No media file provided');
      return res.status(400).json({ message: 'Media file is required' });
    }

    console.log('✅ Media file received, validating...');

    // Validate media type
    const allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const allowedVideoTypes = ['video/mp4', 'video/webm', 'video/quicktime'];
    const allowedTypes = [...allowedImageTypes, ...allowedVideoTypes];

    console.log('Media mimetype:', media.mimetype);
    console.log('Allowed types:', allowedTypes);

    if (!allowedTypes.includes(media.mimetype)) {
      console.log('❌ Invalid file type:', media.mimetype);
      return res.status(400).json({ 
        message: 'Invalid file type. Supported: images (JPEG, PNG, GIF, WebP) and videos (MP4, WebM, QuickTime)' 
      });
    }

    console.log('✅ Media type validation passed');

    // Determine media type if not provided
    let detectedMediaType = media_type;
    if (!detectedMediaType) {
      detectedMediaType = allowedImageTypes.includes(media.mimetype) ? 'image' : 'video';
    }

    // Validate media type matches file type
    if ((detectedMediaType === 'image' && !allowedImageTypes.includes(media.mimetype)) ||
        (detectedMediaType === 'video' && !allowedVideoTypes.includes(media.mimetype))) {
      return res.status(400).json({ 
        message: 'Media type does not match file type' 
      });
    }

    // Upload media to Supabase Storage
    console.log('📤 Uploading media to Supabase Storage...');
    const fileExt = media.originalname.split('.').pop();
    const fileName = `${Math.random().toString(36).substring(7)}.${fileExt}`;
    console.log('Generated filename:', fileName);
    console.log('File size:', media.buffer.length);
    
    const { error: uploadError } = await supabaseAdmin.storage
      .from('post-media')
      .upload(fileName, media.buffer);

    if (uploadError) {
      console.log('❌ Storage upload error:', uploadError);
      throw uploadError;
    }
    
    console.log('✅ Media uploaded to storage successfully');

    // Get public URL for the uploaded media
    const { data: { publicUrl } } = supabaseAdmin.storage
      .from('post-media')
      .getPublicUrl(fileName);

    // Create post record using admin client to bypass RLS
    console.log('=== CREATING POST IN DATABASE ===');
    console.log('User ID:', req.user.id);
    console.log('Caption:', caption);
    console.log('Media URL:', publicUrl);
    console.log('Media Type:', detectedMediaType);
    
    const { data, error } = await supabaseAdmin
      .from('posts')
      .insert([
        {
          user_id: req.user.id,
          caption,
          media_url: publicUrl,
          media_type: detectedMediaType
        }
      ])
      .select()
      .single();
      
    console.log('Database response:', { data, error });

    if (error) throw error;

    // Process mentions if provided
    if (mentions && Array.isArray(mentions)) {
      for (const username of mentions) {
        // Find user by username
        const { data: mentionedUser } = await supabaseAdmin
          .from('profiles')
          .select('id')
          .eq('username', username)
          .single();

        if (mentionedUser) {
          await supabaseAdmin
            .from('post_mentions')
            .insert([{
              post_id: data.id,
              mentioned_user_id: mentionedUser.id
            }]);
        }
      }
    }

    // Hashtags are now stored directly in the caption text
    // No need for separate hashtag processing

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get feed posts (posts from followed users) - MUST be before /:id route
router.get('/feed', validateAuth, async (req, res) => {
  try {
    console.log('=== FEED REQUEST RECEIVED ===');
    console.log('User ID:', req.user?.id);
    console.log('User email:', req.user?.email);
    console.log('Query params:', req.query);
    console.log('Headers:', req.headers);
    
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const userId = req.user.id;

    // Get followed users
    const { data: following, error: followingError } = await supabaseAdmin
      .from('follows')
      .select('following_id')
      .eq('follower_id', userId);

    if (followingError) {
      console.log('❌ Error getting following:', followingError);
      throw followingError;
    }

    console.log('Following users:', following?.length || 0);
    const followingIds = following.map(f => f.following_id);
    
    // Always include own posts in feed
    followingIds.push(userId);
    
    console.log('✅ Including own posts, total users:', followingIds.length);

    // If user doesn't follow anyone (new user), show all posts (discovery mode)
    let query = supabaseAdmin
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        likes(count)
      `, { count: 'exact' });

    // If following someone, filter by followed users
    // Otherwise show all posts (discovery mode for new users)
    if (followingIds.length > 1) { // > 1 because we always have userId
      query = query.in('user_id', followingIds);
      console.log('✅ Filtered feed: showing posts from followed users');
    } else {
      console.log('✅ Discovery mode: showing all posts (new user)');
    }

    const { data, error, count } = await query
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) {
      console.log('❌ Error getting posts:', error);
      throw error;
    }

    console.log('✅ Posts retrieved:', data?.length || 0);

    // Get user's likes for all posts
    const postIds = data.map(post => post.id);
    const { data: userLikes, error: likesError } = await supabaseAdmin
      .from('likes')
      .select('post_id')
      .eq('user_id', userId)
      .in('post_id', postIds);

    if (likesError) {
      console.log('❌ Error getting user likes:', likesError);
      throw likesError;
    }

    const likedPostIds = new Set(userLikes.map(like => like.post_id));
    console.log('✅ User liked posts:', likedPostIds.size);

    // Transform data to include likes count and is_liked status
    const postsWithLikes = data.map(post => ({
      ...post,
      likes_count: post.likes?.[0]?.count || 0,
      is_liked: likedPostIds.has(post.id),
      likes: undefined // Remove the likes array from response
    }));

    console.log('✅ Feed response sent successfully');
    res.json({
      posts: postsWithLikes,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.log('❌ Feed error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get single post
router.get('/:id', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const { data, error } = await supabaseAdmin
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        comments (
          id,
          content,
          parent_comment_id,
          created_at,
          profiles:user_id (username, avatar_url)
        ),
        likes(count)
      `)
      .eq('id', id)
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'Post not found' });

    // Check if user liked this post
    const { data: userLike, error: likeError } = await supabaseAdmin
      .from('likes')
      .select('id')
      .eq('user_id', userId)
      .eq('post_id', id)
      .single();

    const isLiked = !likeError && userLike;

    // Transform data to include likes count and is_liked status
    const postWithLikes = {
      ...data,
      likes_count: data.likes?.[0]?.count || 0,
      is_liked: isLiked,
      likes: undefined // Remove the likes array from response
    };

    res.json(postWithLikes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete post
router.delete('/:id', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if post exists and belongs to user
    const { data: post, error: fetchError } = await supabaseAdmin
      .from('posts')
      .select('user_id, media_url')
      .eq('id', id)
      .single();

    if (fetchError) throw fetchError;
    if (!post) return res.status(404).json({ message: 'Post not found' });
    if (post.user_id !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    // Delete media from storage
    const mediaName = post.media_url.split('/').pop();
    const { error: storageError } = await supabaseAdmin.storage
      .from('post-media')
      .remove([mediaName]);

    if (storageError) throw storageError;

    // Delete post
    const { error } = await supabaseAdmin
      .from('posts')
      .delete()
      .eq('id', id);

    if (error) throw error;

    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Like/Unlike post
router.post('/:id/like', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if already liked
    const { data: existingLike } = await supabaseAdmin
      .from('likes')
      .select()
      .eq('post_id', id)
      .eq('user_id', userId)
      .single();

    if (existingLike) {
      // Unlike
      const { error } = await supabaseAdmin
        .from('likes')
        .delete()
        .eq('post_id', id)
        .eq('user_id', userId);

      if (error) throw error;

      // Delete like notification
      await supabaseAdmin
        .from('notifications')
        .delete()
        .eq('post_id', id)
        .eq('actor_id', userId)
        .eq('type', 'like');

      res.json({ message: 'Post unliked successfully' });
    } else {
      // Like
      const { error } = await supabaseAdmin
        .from('likes')
        .insert([{ post_id: id, user_id: userId }]);

      if (error) throw error;

      // Get post owner to create notification
      const { data: post } = await supabaseAdmin
        .from('posts')
        .select('user_id')
        .eq('id', id)
        .single();

      if (post && post.user_id !== userId) {
        await createNotification(post.user_id, userId, 'like', id);
      }

      res.json({ message: 'Post liked successfully' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get comments for a post
router.get('/:id/comments', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    // Get top-level comments (parent_comment_id is null)
    const { data: comments, error, count } = await supabaseAdmin
      .from('comments')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        comment_likes(count),
        comment_dislikes(count)
      `, { count: 'exact' })
      .eq('post_id', id)
      .is('parent_comment_id', null)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;

    // Get comment IDs for all comments (including replies)
    const commentIds = comments.map(c => c.id);
    
    // Get replies for each comment
    if (commentIds.length > 0) {
      const { data: replies, error: repliesError } = await supabaseAdmin
        .from('comments')
        .select(`
          *,
          profiles:user_id (username, avatar_url),
          comment_likes(count),
          comment_dislikes(count)
        `)
        .in('parent_comment_id', commentIds)
        .order('created_at', { ascending: true });

      if (repliesError) throw repliesError;

      // Add replies to main comment list for easier processing
      const allComments = [...comments, ...replies];
      
      // Get user's likes and dislikes for all comments
      const allCommentIds = allComments.map(c => c.id);
      const { data: userLikes } = await supabaseAdmin
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', userId)
        .in('comment_id', allCommentIds);
      
      const { data: userDislikes } = await supabaseAdmin
        .from('comment_dislikes')
        .select('comment_id')
        .eq('user_id', userId)
        .in('comment_id', allCommentIds);
      
      const likedCommentIds = new Set(userLikes?.map(l => l.comment_id) || []);
      const dislikedCommentIds = new Set(userDislikes?.map(d => d.comment_id) || []);
      
      // Process all comments (main and replies)
      allComments.forEach(comment => {
        comment.likes_count = comment.comment_likes?.[0]?.count || 0;
        comment.dislikes_count = comment.comment_dislikes?.[0]?.count || 0;
        comment.is_liked = likedCommentIds.has(comment.id);
        comment.is_disliked = dislikedCommentIds.has(comment.id);
        delete comment.comment_likes;
        delete comment.comment_dislikes;
      });

      // Group replies by parent_comment_id
      const repliesMap = {};
      replies.forEach(reply => {
        if (!repliesMap[reply.parent_comment_id]) {
          repliesMap[reply.parent_comment_id] = [];
        }
        repliesMap[reply.parent_comment_id].push(reply);
      });

      // Add replies to comments
      comments.forEach(comment => {
        comment.replies = repliesMap[comment.id] || [];
      });
    }

    res.json({
      comments,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add comment to post
router.post('/:id/comments', validateAuth, validateUUID, validateComment, async (req, res) => {
  try {
    const { id } = req.params;
    const { content, parent_comment_id } = req.body;
    const userId = req.user.id;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ message: 'Comment content is required' });
    }

    // Check if post exists and get owner
    const { data: post, error: postError } = await supabaseAdmin
      .from('posts')
      .select('id, user_id')
      .eq('id', id)
      .single();

    if (postError || !post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // If replying to a comment, check if parent comment exists
    if (parent_comment_id) {
      const { data: parentComment, error: parentError } = await supabaseAdmin
        .from('comments')
        .select('id')
        .eq('id', parent_comment_id)
        .eq('post_id', id)
        .single();

      if (parentError || !parentComment) {
        return res.status(404).json({ message: 'Parent comment not found' });
      }
    }

    // Create comment
    const { data, error } = await supabaseAdmin
      .from('comments')
      .insert([
        {
          post_id: id,
          user_id: userId,
          parent_comment_id: parent_comment_id || null,
          content: content.trim()
        }
      ])
      .select(`
        *,
        profiles:user_id (username, avatar_url)
      `)
      .single();

    if (error) throw error;

    // Create notification for post owner
    if (post.user_id !== userId) {
      await createNotification(post.user_id, userId, 'comment', id, data.id);
    }

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update comment
router.put('/:id/comments/:commentId', validateAuth, validateUUID, validateCommentId, validateComment, async (req, res) => {
  try {
    const { id, commentId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ message: 'Comment content is required' });
    }

    // Check if comment exists and belongs to user
    const { data: comment, error: fetchError } = await supabaseAdmin
      .from('comments')
      .select('user_id, post_id')
      .eq('id', commentId)
      .eq('post_id', id)
      .single();

    if (fetchError || !comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    if (comment.user_id !== userId) {
      return res.status(403).json({ message: 'Unauthorized to edit this comment' });
    }

    // Update comment
    const { data: updatedComment, error } = await supabaseAdmin
      .from('comments')
      .update({
        content: content.trim(),
        updated_at: new Date().toISOString()
      })
      .eq('id', commentId)
      .select(`
        *,
        profiles:user_id (username, avatar_url)
      `)
      .single();

    if (error) throw error;

    res.json(updatedComment);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete comment
router.delete('/:id/comments/:commentId', validateAuth, validateUUID, validateCommentId, async (req, res) => {
  try {
    const { id, commentId } = req.params;
    const userId = req.user.id;

    // Check if comment exists and belongs to user
    const { data: comment, error: fetchError } = await supabaseAdmin
      .from('comments')
      .select('user_id, post_id')
      .eq('id', commentId)
      .eq('post_id', id)
      .single();

    if (fetchError || !comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    if (comment.user_id !== userId) {
      return res.status(403).json({ message: 'Unauthorized to delete this comment' });
    }

    // Delete comment
    const { error } = await supabaseAdmin
      .from('comments')
      .delete()
      .eq('id', commentId);

    if (error) throw error;

    res.json({ message: 'Comment deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Like a comment
router.post('/:id/comments/:commentId/like', validateAuth, validateUUID, validateCommentId, async (req, res) => {
  try {
    const { id: postId, commentId } = req.params;
    const userId = req.user.id;

    // Check if post exists
    const { data: post, error: postError } = await supabaseAdmin
      .from('posts')
      .select('id')
      .eq('id', postId)
      .single();

    if (postError || !post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Check if comment exists and belongs to this post
    const { data: comment, error: commentError } = await supabaseAdmin
      .from('comments')
      .select('id, user_id')
      .eq('id', commentId)
      .eq('post_id', postId)
      .single();

    if (commentError || !comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    // Check if user already liked the comment
    const { data: existingLike } = await supabaseAdmin
      .from('comment_likes')
      .select('id')
      .eq('comment_id', commentId)
      .eq('user_id', userId)
      .single();

    if (existingLike) {
      // Unlike: delete the like
      await supabaseAdmin
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', userId);

      // Check if user has a dislike, remove it too
      const { data: existingDislike } = await supabaseAdmin
        .from('comment_dislikes')
        .select('id')
        .eq('comment_id', commentId)
        .eq('user_id', userId)
        .single();

      if (existingDislike) {
        await supabaseAdmin
          .from('comment_dislikes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);
      }

      return res.json({ isLiked: false, isDisliked: false });
    }

    // Like: insert the like
    // First, check if user has a dislike and remove it
    const { data: existingDislike } = await supabaseAdmin
      .from('comment_dislikes')
      .select('id')
      .eq('comment_id', commentId)
      .eq('user_id', userId)
      .single();

    if (existingDislike) {
      await supabaseAdmin
        .from('comment_dislikes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', userId);
    }

    // Insert the like
    const { error: likeError } = await supabaseAdmin
      .from('comment_likes')
      .insert({
        comment_id: commentId,
        user_id: userId
      });

    if (likeError) throw likeError;

    // Create notification if comment owner is not the liker
    if (comment.user_id !== userId) {
      await createNotification(comment.user_id, userId, 'comment_like', postId, commentId);
    }

    res.json({ isLiked: true, isDisliked: false });
  } catch (error) {
    console.error('Error liking comment:', error);
    res.status(500).json({ error: error.message });
  }
});

// Dislike a comment
router.post('/:id/comments/:commentId/dislike', validateAuth, validateUUID, validateCommentId, async (req, res) => {
  try {
    const { id: postId, commentId } = req.params;
    const userId = req.user.id;

    // Check if post exists
    const { data: post, error: postError } = await supabaseAdmin
      .from('posts')
      .select('id')
      .eq('id', postId)
      .single();

    if (postError || !post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Check if comment exists and belongs to this post
    const { data: comment, error: commentError } = await supabaseAdmin
      .from('comments')
      .select('id')
      .eq('id', commentId)
      .eq('post_id', postId)
      .single();

    if (commentError || !comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    // Check if user already disliked the comment
    const { data: existingDislike } = await supabaseAdmin
      .from('comment_dislikes')
      .select('id')
      .eq('comment_id', commentId)
      .eq('user_id', userId)
      .single();

    if (existingDislike) {
      // Undislike: delete the dislike
      await supabaseAdmin
        .from('comment_dislikes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', userId);

      return res.json({ isLiked: false, isDisliked: false });
    }

    // Dislike: insert the dislike
    // First, check if user has a like and remove it
    const { data: existingLike } = await supabaseAdmin
      .from('comment_likes')
      .select('id')
      .eq('comment_id', commentId)
      .eq('user_id', userId)
      .single();

    if (existingLike) {
      await supabaseAdmin
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', userId);
    }

    // Insert the dislike
    const { error: dislikeError } = await supabaseAdmin
      .from('comment_dislikes')
      .insert({
        comment_id: commentId,
        user_id: userId
      });

    if (dislikeError) throw dislikeError;

    res.json({ isLiked: false, isDisliked: true });
  } catch (error) {
    console.error('Error disliking comment:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update post
router.put('/:id', validateAuth, validateUUID, validatePostUpdate, async (req, res) => {
  try {
    const { id } = req.params;
    const { caption } = req.body;
    const userId = req.user.id;

    // Check if post exists and belongs to user
    const { data: post, error: fetchError } = await supabaseAdmin
      .from('posts')
      .select('user_id')
      .eq('id', id)
      .single();

    if (fetchError || !post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.user_id !== userId) {
      return res.status(403).json({ message: 'Unauthorized to update this post' });
    }

    // Update post
    const { data, error } = await supabaseAdmin
      .from('posts')
      .update({
        caption: caption || null,
        updated_at: new Date()
      })
      .eq('id', id)
      .select(`
        *,
        profiles:user_id (username, avatar_url)
      `)
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get posts by hashtag
router.get('/hashtag/:hashtag', validateAuth, async (req, res) => {
  try {
    const { hashtag } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const userId = req.user.id;

    console.log('=== HASHTAG SEARCH ===');
    console.log('Searching for hashtag:', hashtag);
    console.log('Page:', page, 'Limit:', limit);

    // Search for posts where caption contains the hashtag
    const { data, error, count } = await supabaseAdmin
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        likes(count)
      `, { count: 'exact' })
      .ilike('caption', `%#${hashtag.toLowerCase()}%`)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;

    console.log('Found posts:', data.length);

    // Get user's likes for all posts
    const postIds = data.map(post => post.id);
    const { data: userLikes, error: likesError } = await supabaseAdmin
      .from('likes')
      .select('post_id')
      .eq('user_id', userId)
      .in('post_id', postIds);

    if (likesError) throw likesError;

    const likedPostIds = new Set(userLikes.map(like => like.post_id));

    // Transform data to include likes count and is_liked status
    const postsWithLikes = data.map(post => ({
      ...post,
      likes_count: post.likes?.[0]?.count || 0,
      is_liked: likedPostIds.has(post.id),
      likes: undefined // Remove the likes array from response
    }));

    console.log('Returning posts:', postsWithLikes.length);

    res.json({
      posts: postsWithLikes,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Hashtag search error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get posts where user is mentioned
router.get('/mentions', validateAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const userId = req.user.id;

    const { data, error, count } = await supabaseAdmin
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, avatar_url),
        likes(count),
        post_mentions!inner(mentioned_user_id)
      `, { count: 'exact' })
      .eq('post_mentions.mentioned_user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;

    // Get user's likes for all posts
    const postIds = data.map(post => post.id);
    const { data: userLikes, error: likesError } = await supabaseAdmin
      .from('likes')
      .select('post_id')
      .eq('user_id', userId)
      .in('post_id', postIds);

    if (likesError) throw likesError;

    const likedPostIds = new Set(userLikes.map(like => like.post_id));

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

// Save/Unsave post
router.post('/:id/save', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if post exists
    const { data: post, error: postError } = await supabaseAdmin
      .from('posts')
      .select('id')
      .eq('id', id)
      .single();

    if (postError || !post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Check if already saved
    const { data: existingSave, error: checkError } = await supabaseAdmin
      .from('saved_posts')
      .select('id')
      .eq('user_id', userId)
      .eq('post_id', id)
      .single();

    if (existingSave) {
      return res.json({ message: 'Post already saved', saved: true });
    }

    // Save post
    const { data, error } = await supabaseAdmin
      .from('saved_posts')
      .insert([{
        user_id: userId,
        post_id: id
      }])
      .select()
      .single();

    if (error) throw error;

    res.json({ message: 'Post saved successfully', saved: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Unsave post
router.delete('/:id/save', validateAuth, validateUUID, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Remove saved post
    const { error } = await supabaseAdmin
      .from('saved_posts')
      .delete()
      .eq('user_id', userId)
      .eq('post_id', id);

    if (error) throw error;

    res.json({ message: 'Post unsaved successfully', saved: false });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;