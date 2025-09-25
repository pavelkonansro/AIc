# 🎯 ФИНАЛЬНЫЙ ПЛАН РАЗВЕРТЫВАНИЯ AIc на Beget

## ✅ Данные для подключения:
- **Домен:** konans6z.beget.tech
- **SSH:** konans6z@konans6z.beget.tech  
- **Пароль SSH:** gP19qe3x
- **MySQL База:** konans6z_aic
- **MySQL Пароль:** vbftyjkT1984$

## 🚀 ПОШАГОВЫЙ ПЛАН:

### 1. Загрузить файлы на сервер (выберите способ):

#### Способ A: Автоматический (рекомендуется)
```bash
./upload-to-beget.sh
# Введите пароль: gP19qe3x (будет запрошен несколько раз)
```

#### Способ B: Ручная загрузка через файловый менеджер Beget
Загрузите эти файлы в корневую папку домена:
- `server-beget.js` 
- `package-beget.json` → переименовать в `package.json`
- `.env.beget` → переименовать в `.env`
- `create-mysql-schema.sql`

### 2. Подключиться по SSH:
```bash
ssh konans6z@konans6z.beget.tech
# Пароль: gP19qe3x
```

### 3. На сервере выполнить:
```bash
# Установить зависимости Node.js
npm install --production

# Проверить что файлы на месте
ls -la
```

### 4. Создать таблицы в MySQL:
- Открыть phpMyAdmin в панели Beget
- Выбрать базу `konans6z_aic`
- Выполнить SQL из файла `create-mysql-schema.sql`
- Должно создаться 17 таблиц

### 5. Запустить API сервер:
```bash
node server-beget.js
```

### 6. Тестировать API:
```bash
# В другом терминале или браузере:
curl https://konans6z.beget.tech/health
curl -X POST https://konans6z.beget.tech/auth/guest
```

## 📱 Flutter приложение готово!
Конфигурация уже обновлена на ваш домен. Просто запустите:
```bash
cd apps/mobile
flutter run
```

## 🎉 Ожидаемый результат:
- ✅ API работает на https://konans6z.beget.tech
- ✅ SSL сертификат автоматически 
- ✅ MySQL база с privacy-by-design архитектурой
- ✅ Flutter приложение подключается к production серверу
- ✅ Можно тестировать с любых устройств в интернете

**Время развертывания: ~15-20 минут**

## 🆘 Если что-то не работает:
1. Проверьте логи: `tail -f /var/log/nodejs/error.log`
2. Проверьте процессы: `ps aux | grep node`
3. Проверьте порты: `netstat -tlnp | grep :3000`
4. Перезапустите: `pkill node && node server-beget.js`