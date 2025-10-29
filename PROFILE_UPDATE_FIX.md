# 🔧 ИСПРАВЛЕНИЕ ОШИБКИ "Cannot coerce the result to a single JSON object"

## 🐛 **ПРОБЛЕМА:**
При попытке обновить поле `name` в профиле возникает ошибка:
```
Exception: Failed to update profile: Cannot coerce the result to a single JSON object
```

## 🔍 **ДИАГНОСТИКА:**

### **1. Проверьте, что поле `name` существует в базе данных:**

Выполните в SQL Editor Supabase:
```sql
-- Проверить структуру таблицы profiles
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;
```

### **2. Если поле `name` отсутствует, примените миграцию:**

```sql
-- Добавить поле name
ALTER TABLE profiles ADD COLUMN name TEXT;

-- Обновить существующие записи
UPDATE profiles SET name = username WHERE name IS NULL;

-- Сделать поле обязательным
ALTER TABLE profiles ALTER COLUMN name SET NOT NULL;

-- Добавить комментарий
COMMENT ON COLUMN profiles.name IS 'User display name (different from username)';
```

### **3. Проверьте, что миграция применилась:**

```sql
-- Проверить, что поле name существует
SELECT id, username, name, email FROM profiles LIMIT 5;
```

## 🔧 **ИСПРАВЛЕНИЯ В КОДЕ:**

### **1. Backend (user.routes.js):**
- ✅ Добавлено логирование для отладки
- ✅ Исправлен возврат полной информации профиля с counts
- ✅ Добавлена обработка ошибок

### **2. Frontend (ApiService):**
- ✅ Добавлена проверка на пустые значения
- ✅ Добавлено логирование ответа сервера
- ✅ Улучшена обработка ошибок

### **3. Frontend (EditProfileScreen):**
- ✅ Добавлено логирование передаваемых данных
- ✅ Улучшена обработка ошибок

## 🚀 **КАК ПРОТЕСТИРОВАТЬ:**

### **1. Применить миграцию в Supabase:**
1. Откройте Supabase Dashboard
2. Перейдите в SQL Editor
3. Выполните миграцию выше
4. Проверьте, что поле `name` добавлено

### **2. Перезапустить сервер:**
```bash
cd E:\fuisorbk\fuisorbk
npm start
```

### **3. Запустить Flutter приложение:**
```bash
cd E:\fuisorbk\fuisorbk\fuisor_app
flutter run -d windows
```

### **4. Протестировать обновление профиля:**
1. Откройте Profile Screen
2. Нажмите "Edit Profile"
3. Измените поле "Name"
4. Нажмите "Done"
5. Проверьте логи в консоли

## 📋 **ЛОГИ ДЛЯ ОТЛАДКИ:**

### **Backend логи (в терминале сервера):**
```
Update profile request: { username: 'testuser', name: 'Test Name', bio: 'Test bio', hasAvatar: false }
Updates to apply: { name: 'Test Name', updated_at: 2024-01-01T00:00:00.000Z }
Profile updated successfully: { id: '...', username: 'testuser', name: 'Test Name', ... }
```

### **Frontend логи (в консоли Flutter):**
```
Updating profile with: name="Test Name", username="testuser", bio="Test bio"
Profile update response status: 200
Profile update response body: {"id":"...","username":"testuser","name":"Test Name",...}
Parsed response data: {id: ..., username: testuser, name: Test Name, ...}
```

## 🎯 **ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:**

После применения миграции и исправлений:
- ✅ Поле `name` успешно обновляется
- ✅ Профиль возвращается с полной информацией
- ✅ Ошибка "Cannot coerce the result to a single JSON object" исчезает
- ✅ Пользователь видит обновленное имя в профиле

## 🔍 **ДОПОЛНИТЕЛЬНАЯ ДИАГНОСТИКА:**

Если проблема сохраняется, проверьте:

### **1. Структуру ответа API:**
```bash
curl -X PUT http://localhost:3000/api/users/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"name": "Test Name"}'
```

### **2. Логи Supabase:**
- Проверьте логи в Supabase Dashboard
- Убедитесь, что нет ошибок RLS

### **3. Проверьте валидацию:**
- Убедитесь, что поле `name` проходит валидацию
- Проверьте, что длина имени в допустимых пределах (1-50 символов)

---

**Следуйте этим шагам для исправления ошибки!** 🔧
