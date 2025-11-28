<?php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once '../config/database.php';
require_once '../utils/jwt.php';
require_once '../utils/validator.php';
require_once '../classes/User.php';

$database = new Database();
$db = $database->getConnection();

$jwt = new JWT();
$user = new User($db);

$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'POST':
        handlePost($data, $user, $jwt, $db);
        break;
    case 'OPTIONS':
        // Handle preflight requests
        http_response_code(200);
        break;
    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
        break;
}

function handlePost($data, $user, $jwt, $db) {
    if (!isset($data['action'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Action required']);
        return;
    }
    
    switch ($data['action']) {
        case 'login':
            handleLogin($data, $user, $jwt);
            break;
        case 'register':
            handleRegister($data, $user, $jwt, $db);
            break;
        case 'verify':
            handleVerify($data, $jwt);
            break;
        case 'logout':
            handleLogout();
            break;
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
            break;
    }
}

function handleLogin($data, $user, $jwt) {
    // Validate input
    if (!isset($data['email']) || !isset($data['password'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Email and password required']);
        return;
    }
    
    $email = trim($data['email']);
    $password = $data['password'];
    $remember = !empty($data['remember']);
    
    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        return;
    }
    
    // Attempt login
    $result = $user->login($email, $password);
    
    if ($result) {
        // Generate JWT token
        $tokenData = [
            'user_id' => $result['user_id'],
            'email' => $result['email'],
            'role' => $result['role'],
            'exp' => $remember ? time() + (30 * 24 * 60 * 60) : time() + (24 * 60 * 60) // 30 days or 1 day
        ];
        
        $token = $jwt->encode($tokenData);
        
        // Update last login
        $user->updateLastLogin($result['user_id']);
        
        // Remove password from response
        if (isset($result['password_hash'])) {
            unset($result['password_hash']);
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'token' => $token,
            'user' => $result
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
    }
}

function handleRegister($data, $user, $jwt, $db) {
    // Validate required fields
    $required = ['full_name', 'email', 'phone', 'password'];
    foreach ($required as $field) {
        if (!isset($data[$field]) || empty(trim($data[$field]))) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => ucfirst($field) . ' is required']);
            return;
        }
    }
    
    // Validate terms acceptance
    if (!isset($data['terms']) || !$data['terms']) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'You must accept the terms and conditions']);
        return;
    }
    
    // Validate email format
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        return;
    }
    
    // Validate password strength
    if (strlen($data['password']) < 6) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Password must be at least 6 characters']);
        return;
    }
    
    // Check if email already exists
    if ($user->emailExists($data['email'])) {
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => 'Email already registered']);
        return;
    }
    
    // Set user data
    $user->full_name = trim($data['full_name']);
    $user->email = trim($data['email']);
    $user->phone = trim($data['phone']);
    $user->password = $data['password'];
    $user->role = 'member';
    $user->status = 'active';
    
    
    // Create user
    if ($user->create()) {
        // Send welcome email
        sendWelcomeEmail($user->email, $user->full_name);
        
        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Registration successful! Please login.'
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Registration failed']);
    }
}

function handleVerify($data, $jwt) {
    if (!isset($data['token'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Token required']);
        return;
    }
    
    $decoded = $jwt->decode($data['token']);
    
    if ($decoded) {
        // Token is valid, return user data
        $user = new User($GLOBALS['db']);
        $user->user_id = $decoded->user_id;
        $user_data = $user->getUserById();
        
        if ($user_data) {
            if (isset($user_data['password_hash'])) {
                unset($user_data['password_hash']);
            }
            echo json_encode([
                'success' => true,
                'user' => $user_data
            ]);
        } else {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'User not found']);
        }
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token']);
    }
}

function handleLogout() {
    // In a stateless JWT system, logout is handled client-side
    // But we can log the logout event if needed
    echo json_encode(['success' => true, 'message' => 'Logged out successfully']);
}

function sendWelcomeEmail($email, $name) {
    // Placeholder for email sending
    // In production, integrate with email service like SendGrid, Mailgun, etc.
    $subject = "Welcome to Seijaku Pilates, $name!";
    $message = "Dear $name,\n\nWelcome to Seijaku Pilates! Your account has been created successfully.\n\nBest regards,\nSeijaku Pilates Team";
    
    // For now, just log the email (replace with actual email sending)
    error_log("Welcome email sent to: $email");
}
?>