# 👤 Username Login API Documentation

## 🚀 **Новая функциональность: Вход по username**

Теперь пользователи могут входить в систему используя либо **email**, либо **username**!

---

## 📋 **API Endpoint**

### **POST** `/api/auth/login`

**Описание:** Вход в систему с использованием email или username

---

## 🔧 **Параметры запроса**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `email_or_username` | string | ✅ | Email или username пользователя |
| `password` | string | ✅ | Пароль пользователя |

---

## 📝 **Примеры запросов**

### ✅ **Вход по email:**
```json
{
  "email_or_username": "user@gmail.com",
  "password": "password123"
}
```

### ✅ **Вход по username:**
```json
{
  "email_or_username": "username123",
  "password": "password123"
}
```

---

## 📊 **Ответы API**

### ✅ **Успешный вход (200 OK):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "email_confirmed_at": "2025-10-22T16:19:08.186353Z",
    "role": "authenticated"
  },
  "session": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 3600
  },
  "profile": {
    "username": "username123",
    "avatar_url": "https://...",
    "bio": "User bio"
  }
}
```

### ❌ **Ошибка валидации (400 Bad Request):**
```json
{
  "message": "Validation failed",
  "errors": [
    {
      "type": "field",
      "msg": "Email or username is required",
      "path": "email_or_username",
      "location": "body"
    }
  ]
}
```

### ❌ **Неверные учетные данные (401 Unauthorized):**
```json
{
  "error": "Invalid username or password"
}
```

---

## 🔍 **Логика работы**

1. **Определение типа входа:**
   - Если `email_or_username` содержит `@` → считается email
   - Если не содержит `@` → считается username

2. **Для email:**
   - Используется напрямую для входа в Supabase Auth

3. **Для username:**
   - Ищется соответствующий email в таблице `profiles`
   - Если найден → используется email для входа
   - Если не найден → возвращается ошибка

---

## 🛡️ **Безопасность**

- ✅ **Валидация входных данных** - проверка обязательных полей
- ✅ **Безопасные сообщения об ошибках** - не раскрывают, существует ли пользователь
- ✅ **JWT токены** - безопасная аутентификация
- ✅ **RLS политики** - защита данных на уровне базы

---

## 🧪 **Тестирование**

### **cURL примеры:**

**Вход по email:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email_or_username":"user@gmail.com","password":"password123"}'
```

**Вход по username:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email_or_username":"username123","password":"password123"}'
```

### **JavaScript пример:**
```javascript
const loginResponse = await fetch('http://localhost:3000/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email_or_username: 'username123', // или 'user@gmail.com'
    password: 'password123'
  })
});

const data = await loginResponse.json();
if (loginResponse.ok) {
  console.log('Login successful:', data.profile.username);
  // Сохранить токен: data.session.access_token
} else {
  console.error('Login failed:', data.error);
}
```

---

## 🎯 **Преимущества**

1. **🎨 Удобство для пользователей** - можно использовать username вместо email
2. **🔒 Безопасность** - сохраняется вся безопасность Supabase Auth
3. **⚡ Производительность** - минимальные дополнительные запросы к БД
4. **🛡️ Надежность** - валидация и обработка ошибок
5. **📱 Совместимость** - работает с существующими клиентами

---

## 🚀 **Статус**

✅ **Готово к продакшену!** Функциональность полностью протестирована и работает корректно.
