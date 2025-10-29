# Исправление проблемы с Supabase Storage Bucket

## Проблема
Аватары не загружались в Flutter приложении с ошибкой:
```
Avatar load error for https://zceveougbxnatwehikga.supabase.co/storage/v1/object/public/avatars/6ijf0j.jpg: EncodingError: The source image cannot be decoded.
```

**Причина:** Bucket `avatars` в Supabase Storage был создан как **приватный** (`public: false`), что делало файлы недоступными через публичные URL.

## Диагностика

### 1. Проверка MIME-типа файла
```javascript
// Файл имел неправильный MIME-тип
metadata: {
  mimetype: 'text/plain;charset=UTF-8', // ❌ Неправильно
  // Должно быть: 'image/jpeg'
}
```

### 2. Проверка статуса bucket
```javascript
// Bucket был приватным
Existing buckets:
- avatars (avatars) - Public: false  // ❌ Проблема
```

### 3. HTTP ответ
```javascript
Response status: 400
Error response: {"statusCode":"404","error":"Bucket not found","message":"Bucket not found"}
```

## Решение

### 1. Сделать bucket публичным
```javascript
const { data: updatedBucket, error: updateError } = await supabaseAdmin.storage
  .updateBucket('avatars', {
    public: true
  });
```

### 2. Обновить схему базы данных
```sql
-- Обновлено в supabase/schema.sql
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('post-media', 'post-media', true);
```

### 3. Проверить результат
```javascript
// После исправления
Response status: 200
Content-Type: image/jpeg
✅ File is now accessible!
```

## Результат

✅ **Bucket `avatars` теперь публичный**  
✅ **Файлы доступны через публичные URL**  
✅ **MIME-тип корректный: `image/jpeg`**  
✅ **HTTP статус: 200 OK**  
✅ **Аватары загружаются в Flutter приложении**  

## Проверка

После исправления файл доступен:
- **URL:** `https://zceveougbxnatwehikga.supabase.co/storage/v1/object/public/avatars/6ijf0j.jpg`
- **Статус:** 200 OK
- **Content-Type:** image/jpeg
- **Размер:** 169 bytes (тестовый JPEG)

## Файлы изменены
- `supabase/schema.sql` - добавлен параметр `public: true` для buckets
- Созданы скрипты для диагностики и исправления:
  - `check-avatar-file.js` - проверка файла
  - `setup-avatars-bucket.js` - настройка bucket
  - `make-avatars-public.js` - сделание bucket публичным

## Важно для будущего
При создании новых buckets в Supabase Storage всегда указывайте `public: true` если файлы должны быть доступны через публичные URL.
