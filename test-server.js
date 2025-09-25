// Простой Express сервер для диагностики
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/test', (req, res) => {
  res.json({ message: 'Express сервер работает!' });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`🔥 Express тест сервер запущен на http://127.0.0.1:${PORT}`);
  console.log(`🔍 Тест: curl -X GET http://127.0.0.1:${PORT}/health`);
});