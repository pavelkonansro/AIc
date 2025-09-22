const io = require('socket.io-client');

async function testWebSocket() {
    console.log('🔄 Создаем тестового пользователя...');

    // Создаем тестового пользователя
    const userResponse = await fetch('http://localhost:3000/test/create-user', { method: 'POST' });
    const userData = await userResponse.json();
    console.log('👤 Пользователь создан:', userData);

    // Создаем сессию чата
    const sessionResponse = await fetch('http://localhost:3000/test/create-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: userData.userId })
    });
    const sessionData = await sessionResponse.json();
    console.log('💬 Сессия создана:', sessionData);

    // Подключаемся к WebSocket
    console.log('🔌 Подключаемся к WebSocket...');
    const socket = io('http://localhost:3000/chat');

    socket.on('connect', () => {
        console.log('✅ WebSocket подключен, ID:', socket.id);

        // Присоединяемся к сессии
        socket.emit('join_session', { sessionId: sessionData.sessionId });
        console.log('🏠 Присоединились к сессии:', sessionData.sessionId);

        // Отправляем тестовое сообщение
        setTimeout(() => {
            console.log('📤 Отправляем тестовое сообщение...');
            socket.emit('chat:message', {
                sessionId: sessionData.sessionId,
                text: 'Привет! Как дела?'
            });
        }, 1000);
    });

    socket.on('message', (data) => {
        console.log(`📨 Получено сообщение [${data.role}]:`, data.content);
        if (data.model) {
            console.log(`🤖 Модель: ${data.model}`);
        }
        if (data.provider) {
            console.log(`🏢 Провайдер: ${data.provider}`);
        }
        if (data.usage) {
            console.log(`📊 Использование токенов:`, data.usage);
        }
    });

    socket.on('typing', (data) => {
        if (data.isTyping) {
            console.log('⌨️ AIc печатает...');
        } else {
            console.log('⌨️ Печать завершена');
        }
    });

    socket.on('error', (data) => {
        console.error('❌ Ошибка WebSocket:', data);
    });

    socket.on('disconnect', () => {
        console.log('❌ WebSocket отключен');
    });

    // Завершаем через 30 секунд
    setTimeout(() => {
        console.log('🔚 Завершение теста');
        socket.disconnect();
        process.exit(0);
    }, 30000);
}

testWebSocket().catch(console.error);