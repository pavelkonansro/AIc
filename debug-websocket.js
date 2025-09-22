const io = require('socket.io-client');

async function debugWebSocket() {
    console.log('🔄 Создаем тестового пользователя...');

    // Создаем тестового пользователя
    const userResponse = await fetch('http://localhost:3000/test/create-user', { method: 'POST' });
    const userData = await userResponse.json();
    console.log('👤 Пользователь создан:', userData.userId);

    // Создаем сессию чата
    const sessionResponse = await fetch('http://localhost:3000/test/create-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: userData.userId })
    });
    const sessionData = await sessionResponse.json();
    console.log('💬 Сессия создана:', sessionData.sessionId);

    // Подключаемся к WebSocket
    console.log('🔌 Подключаемся к WebSocket...');
    const socket = io('http://localhost:3000/chat', { forceNew: true });

    let messageCount = 0;

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
                text: 'Тест дублирования'
            });
        }, 1000);
    });

    socket.on('message', (data) => {
        messageCount++;
        console.log(`📨 Сообщение #${messageCount} [${data.role}]:`, data.content);

        if (data.role === 'user' && messageCount > 1) {
            console.log('❌ ДУБЛИРОВАНИЕ ОБНАРУЖЕНО! Сообщение пользователя получено дважды');
        }
    });

    socket.on('typing', (data) => {
        if (data.isTyping) {
            console.log('⌨️ AIc печатает...');
        }
    });

    socket.on('error', (data) => {
        console.error('❌ Ошибка WebSocket:', data);
    });

    // Завершаем через 15 секунд
    setTimeout(() => {
        console.log('🔚 Завершение теста');
        if (messageCount === 1) {
            console.log('✅ ТЕСТ ПРОЙДЕН: Дублирования нет!');
        } else {
            console.log(`❌ ТЕСТ НЕ ПРОЙДЕН: Получено ${messageCount} сообщений вместо 1`);
        }
        socket.disconnect();
        process.exit(0);
    }, 15000);
}

debugWebSocket().catch(console.error);