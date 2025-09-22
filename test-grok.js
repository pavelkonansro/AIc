const io = require('socket.io-client');

async function testGrokConnection() {
    console.log('🚀 Тестируем подключение к Grok через OpenRouter...');

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
    const socket = io('http://localhost:3000/chat');

    socket.on('connect', () => {
        console.log('✅ WebSocket подключен, ID:', socket.id);

        // Присоединяемся к сессии
        socket.emit('join_session', { sessionId: sessionData.sessionId });
        console.log('🏠 Присоединились к сессии:', sessionData.sessionId);

        // Отправляем тестовое сообщение
        setTimeout(() => {
            console.log('📤 Отправляем тестовое сообщение для Grok...');
            socket.emit('chat:message', {
                sessionId: sessionData.sessionId,
                text: 'Привет! Расскажи о себе кратко.'
            });
        }, 1000);
    });

    socket.on('message', (data) => {
        console.log(`📨 Сообщение [${data.role}]:`, data.content);

        if (data.role === 'assistant') {
            console.log('🤖 Информация о модели:', {
                model: data.model,
                provider: data.provider,
                usage: data.usage
            });

            if (data.usage) {
                console.log(`📊 Токены: ${data.usage.total_tokens} (вопрос: ${data.usage.prompt_tokens}, ответ: ${data.usage.completion_tokens})`);
            }
        }
    });

    socket.on('typing', (data) => {
        if (data.isTyping) {
            console.log('⌨️ Grok печатает...');
        } else {
            console.log('⌨️ Печать завершена');
        }
    });

    socket.on('disconnect', () => {
        console.log('❌ WebSocket отключен');
    });

    // Закрываем соединение через 30 секунд
    setTimeout(() => {
        console.log('⏰ Завершаем тест...');
        socket.disconnect();
        process.exit(0);
    }, 30000);
}

// Запускаем тест
testGrokConnection().catch(console.error);