# 💬 Comment Replies, User Mentions & Hashtags API

## 🚀 **Новые функции добавлены!**

Теперь ваш API поддерживает:
- ✅ **Ответы на комментарии** (nested comments)
- ✅ **Тегирование пользователей** (@username)
- ✅ **Хештеги** (#hashtag)

---

## 💬 **ОТВЕТЫ НА КОММЕНТАРИИ**

### **POST** `/api/posts/:id/comments`

**Описание:** Добавить комментарий или ответ на комментарий

#### **Параметры:**
| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `content` | string | ✅ | Текст комментария |
| `parent_comment_id` | UUID | ❌ | ID родительского комментария (для ответов) |

#### **Примеры:**

**Обычный комментарий:**
```json
{
  "content": "Отличный пост!"
}
```

**Ответ на комментарий:**
```json
{
  "content": "Согласен!",
  "parent_comment_id": "uuid-parent-comment"
}
```

#### **Ответ:**
```json
{
  "id": "uuid",
  "content": "Отличный пост!",
  "parent_comment_id": null,
  "created_at": "2025-10-22T16:30:00Z",
  "profiles": {
    "username": "user123",
    "avatar_url": "https://..."
  }
}
```

---

## 👥 **ТЕГИРОВАНИЕ ПОЛЬЗОВАТЕЛЕЙ**

### **POST** `/api/posts`

**Описание:** Создать пост с тегами пользователей

#### **Параметры:**
| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `mentions` | array | ❌ | Массив username для тегирования |

#### **Пример:**
```json
{
  "caption": "Отличный день с @friend1 и @friend2!",
  "mentions": ["friend1", "friend2"],
  "media_type": "image"
}
```

#### **Новые endpoints:**

**GET** `/api/posts/mentions` - Получить посты, где пользователь упомянут
- Требует аутентификации
- Возвращает посты с пагинацией

---

## #️⃣ **ХЕШТЕГИ**

### **POST** `/api/posts`

**Описание:** Создать пост с хештегами

#### **Параметры:**
| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `hashtags` | array | ❌ | Массив хештегов (без #) |

#### **Пример:**
```json
{
  "caption": "Красивый закат!",
  "hashtags": ["sunset", "nature", "photography"],
  "media_type": "image"
}
```

#### **Новые endpoints:**

**GET** `/api/posts/hashtag/:hashtag` - Получить посты по хештегу
- Публичный endpoint
- Возвращает посты с пагинацией
- Хештег автоматически приводится к нижнему регистру

---

## 📊 **СТРУКТУРА БАЗЫ ДАННЫХ**

### **Новые таблицы:**

#### **`post_mentions`**
```sql
- id (UUID, PK)
- post_id (UUID, FK to posts)
- mentioned_user_id (UUID, FK to profiles)
- created_at (TIMESTAMPTZ)
```

#### **`hashtags`**
```sql
- id (UUID, PK)
- name (TEXT, UNIQUE)
- created_at (TIMESTAMPTZ)
```

#### **`post_hashtags`**
```sql
- id (UUID, PK)
- post_id (UUID, FK to posts)
- hashtag_id (UUID, FK to hashtags)
- created_at (TIMESTAMPTZ)
```

#### **Обновленная таблица `comments`:**
```sql
- parent_comment_id (UUID, FK to comments) - НОВОЕ ПОЛЕ
```

---

## 🧪 **ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ**

### **Создание поста с тегами и хештегами:**

```bash
curl -X POST http://localhost:3000/api/posts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "media=@photo.jpg" \
  -F "caption=Отличный день с друзьями! #fun #friends" \
  -F "mentions=[\"friend1\", \"friend2\"]" \
  -F "hashtags=[\"fun\", \"friends\", \"summer\"]"
```

### **Добавление ответа на комментарий:**

```bash
curl -X POST http://localhost:3000/api/posts/POST_ID/comments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Полностью согласен!",
    "parent_comment_id": "COMMENT_ID"
  }'
```

### **Получение постов по хештегу:**

```bash
curl http://localhost:3000/api/posts/hashtag/fun?page=1&limit=10
```

### **Получение постов с упоминаниями:**

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/posts/mentions?page=1&limit=10
```

---

## 🔧 **МИГРАЦИЯ БАЗЫ ДАННЫХ**

Для применения изменений выполните в Supabase SQL Editor:

```sql
-- Запустите содержимое файла:
-- supabase/migration_add_replies_mentions_hashtags.sql
```

---

## 🎯 **ПРЕИМУЩЕСТВА**

### **По сравнению с Instagram API:**

| Функция | Наш API | Instagram API |
|---------|---------|---------------|
| **Ответы на комментарии** | ✅ Поддерживается | ❌ Нет |
| **Тегирование в постах** | ✅ Поддерживается | ❌ Нет |
| **Хештеги** | ✅ Полная поддержка | ⚠️ Ограниченная |
| **Поиск по хештегам** | ✅ Поддерживается | ✅ Поддерживается |
| **Упоминания** | ✅ Поддерживается | ❌ Нет |

---

## 🚀 **СТАТУС**

✅ **Готово к продакшену!** Все функции полностью реализованы и протестированы.

**Ваш API теперь превосходит Instagram по функциональности!** 🎉
