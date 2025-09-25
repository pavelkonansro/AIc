<?php
/**
 * AIc API Server for Beget Hosting (PHP Version)
 * Privacy-by-design architecture for teen users
 * Compatible with Beget Blog hosting plan
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$DB_HOST = 'localhost';
$DB_USER = 'konans6z_aic';
$DB_PASS = 'vbftyjkT1984$';
$DB_NAME = 'konans6z_aic';

// Get request path and method
$request_uri = $_SERVER['REQUEST_URI'];
$path = parse_url($request_uri, PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// Remove base path if exists
$path = str_replace('/aic-app', '', $path);
$path = trim($path, '/');

// Database connection
function getDBConnection() {
    global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;
    
    try {
        $pdo = new PDO(
            "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
            $DB_USER,
            $DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]
        );
        return $pdo;
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Database connection failed',
            'details' => $e->getMessage()
        ]);
        exit();
    }
}

// Generate UUID v4
function generateUUID() {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}

// Calculate age group
function calculateAgeGroup($birthDate) {
    $today = new DateTime();
    $birth = new DateTime($birthDate);
    $age = $today->diff($birth)->y;
    
    if ($age < 13) return '9-12';
    if ($age < 16) return '13-15';
    return '16-18';
}

// Routes
switch ($path) {
    case 'health':
        if ($method === 'GET') {
            try {
                $pdo = getDBConnection();
                $stmt = $pdo->query('SELECT 1');
                
                echo json_encode([
                    'status' => 'healthy',
                    'timestamp' => date('c'),
                    'database' => 'connected',
                    'server' => 'beget-php-production',
                    'php_version' => PHP_VERSION
                ]);
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode([
                    'status' => 'unhealthy',
                    'error' => $e->getMessage(),
                    'timestamp' => date('c')
                ]);
            }
        }
        break;

    case 'auth/guest':
        if ($method === 'POST') {
            try {
                $pdo = getDBConnection();
                $guestId = generateUUID();
                $now = date('Y-m-d H:i:s');
                
                $stmt = $pdo->prepare(
                    "INSERT INTO users (id, email, username, is_guest, created_at, updated_at) 
                     VALUES (?, ?, ?, ?, ?, ?)"
                );
                
                $username = 'Guest-' . substr($guestId, 0, 8);
                $email = "guest-$guestId@temp.com";
                
                $stmt->execute([$guestId, $email, $username, 1, $now, $now]);
                
                echo json_encode([
                    'success' => true,
                    'user' => [
                        'id' => $guestId,
                        'username' => $username,
                        'isGuest' => true
                    ],
                    'message' => 'Guest user created successfully'
                ]);
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => 'Failed to create guest user',
                    'details' => $e->getMessage()
                ]);
            }
        }
        break;

    case 'auth/register':
        if ($method === 'POST') {
            try {
                $input = json_decode(file_get_contents('php://input'), true);
                
                if (!$input || !isset($input['email'], $input['username'], $input['password'], $input['birthDate'])) {
                    http_response_code(400);
                    echo json_encode([
                        'success' => false,
                        'error' => 'Missing required fields: email, username, password, birthDate'
                    ]);
                    break;
                }
                
                $pdo = getDBConnection();
                
                // Check if user exists
                $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ? OR username = ?');
                $stmt->execute([$input['email'], $input['username']]);
                
                if ($stmt->fetch()) {
                    http_response_code(409);
                    echo json_encode([
                        'success' => false,
                        'error' => 'User with this email or username already exists'
                    ]);
                    break;
                }
                
                // Create user
                $userId = generateUUID();
                $hashedPassword = password_hash($input['password'], PASSWORD_BCRYPT);
                $now = date('Y-m-d H:i:s');
                $ageGroup = calculateAgeGroup($input['birthDate']);
                $country = $input['country'] ?? 'CZ';
                
                $pdo->beginTransaction();
                
                // Insert user
                $stmt = $pdo->prepare(
                    "INSERT INTO users (id, email, username, password_hash, is_guest, created_at, updated_at) 
                     VALUES (?, ?, ?, ?, ?, ?, ?)"
                );
                $stmt->execute([$userId, $input['email'], $input['username'], $hashedPassword, 0, $now, $now]);
                
                // Insert profile
                $stmt = $pdo->prepare(
                    "INSERT INTO profiles (id, user_id, age_group, birth_date, country, created_at, updated_at) 
                     VALUES (?, ?, ?, ?, ?, ?, ?)"
                );
                $stmt->execute([generateUUID(), $userId, $ageGroup, $input['birthDate'], $country, $now, $now]);
                
                $pdo->commit();
                
                echo json_encode([
                    'success' => true,
                    'user' => [
                        'id' => $userId,
                        'email' => $input['email'],
                        'username' => $input['username'],
                        'ageGroup' => $ageGroup
                    ],
                    'message' => 'User registered successfully'
                ]);
                
            } catch (Exception $e) {
                $pdo->rollback();
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => 'Failed to register user',
                    'details' => $e->getMessage()
                ]);
            }
        }
        break;

    case 'debug/tables':
        if ($method === 'GET') {
            try {
                $pdo = getDBConnection();
                $stmt = $pdo->query(
                    "SELECT TABLE_NAME as name, TABLE_ROWS as rows, CREATE_TIME as created
                     FROM information_schema.TABLES 
                     WHERE TABLE_SCHEMA = DATABASE()
                     ORDER BY TABLE_NAME"
                );
                
                $tables = $stmt->fetchAll();
                
                echo json_encode([
                    'success' => true,
                    'database' => $DB_NAME,
                    'tables' => $tables
                ]);
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => 'Failed to get tables info',
                    'details' => $e->getMessage()
                ]);
            }
        }
        break;

    default:
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Endpoint not found',
            'path' => $path,
            'method' => $method,
            'available_endpoints' => [
                'GET /health',
                'POST /auth/guest',
                'POST /auth/register',
                'GET /debug/tables'
            ]
        ]);
        break;
}
?>