import express from 'express';
import { supabaseAdmin } from '../config/supabase.js';
import { validateAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

// Get user notifications
router.get('/', validateAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    // Get notifications with actor profile info
    const { data: notifications, error } = await supabaseAdmin
      .from('notifications')
      .select(`
        id,
        type,
        post_id,
        comment_id,
        is_read,
        created_at,
        actor:actor_id (
          id,
          username,
          name,
          avatar_url
        ),
        post:post_id (
          id,
          media_url,
          media_type,
          caption
        ),
        comment:comment_id (
          id,
          content
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('Error fetching notifications:', error);
      return res.status(500).json({ error: error.message });
    }

    // Get total count
    const { count, error: countError } = await supabaseAdmin
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    if (countError) {
      console.error('Error counting notifications:', countError);
      return res.status(500).json({ error: countError.message });
    }

    // Get unread count
    const { count: unreadCount, error: unreadError } = await supabaseAdmin
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (unreadError) {
      console.error('Error counting unread notifications:', unreadError);
      return res.status(500).json({ error: unreadError.message });
    }

    res.json({
      notifications,
      total: count,
      unreadCount,
      page,
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark notification as read
router.put('/:notificationId/read', validateAuth, async (req, res) => {
  try {
    const notificationId = req.params.notificationId;
    const userId = req.user.id;

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true, updated_at: new Date().toISOString() })
      .eq('id', notificationId)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      console.error('Error marking notification as read:', error);
      return res.status(500).json({ error: error.message });
    }

    res.json(data);
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark all notifications as read
router.put('/read-all', validateAuth, async (req, res) => {
  try {
    const userId = req.user.id;

    const { error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true, updated_at: new Date().toISOString() })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) {
      console.error('Error marking all notifications as read:', error);
      return res.status(500).json({ error: error.message });
    }

    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete notification
router.delete('/:notificationId', validateAuth, async (req, res) => {
  try {
    const notificationId = req.params.notificationId;
    const userId = req.user.id;

    const { error } = await supabaseAdmin
      .from('notifications')
      .delete()
      .eq('id', notificationId)
      .eq('user_id', userId);

    if (error) {
      console.error('Error deleting notification:', error);
      return res.status(500).json({ error: error.message });
    }

    res.json({ message: 'Notification deleted successfully' });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create notification (helper function for other routes)
async function createNotification(userId, actorId, type, postId = null, commentId = null) {
  try {
    // Don't create notification if user is notifying themselves
    if (userId === actorId) {
      return null;
    }

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .insert({
        user_id: userId,
        actor_id: actorId,
        type,
        post_id: postId,
        comment_id: commentId,
        is_read: false
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating notification:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error creating notification:', error);
    return null;
  }
}

export { router, createNotification };

