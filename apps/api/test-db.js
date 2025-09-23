// Простой тест подключения к новой базе данных
const { PrismaClient } = require('@prisma/client')

async function testConnection() {
  const prisma = new PrismaClient()
  
  try {
    console.log('Тестирую подключение к базе данных...')
    
    // Попробуем создать пользователя с новой схемой
    const user = await prisma.user.create({
      data: {
        role: 'child',
        locale: 'ru',
        birthdate: new Date('2010-01-01'),
        consentVersion: 1,
      }
    })
    
    console.log('✅ Пользователь создан:', user)
    
    // Создадим согласие
    const consent = await prisma.consent.create({
      data: {
        userId: user.id,
        consentType: 'tos',
        version: 1,
        scope: 'basic',
      }
    })
    
    console.log('✅ Согласие создано:', consent)
    
    // Получим всех пользователей
    const users = await prisma.user.findMany({
      include: {
        consents: true,
      }
    })
    
    console.log('✅ Все пользователи:', users)
    
  } catch (error) {
    console.error('❌ Ошибка:', error.message)
  } finally {
    await prisma.$disconnect()
  }
}

testConnection()