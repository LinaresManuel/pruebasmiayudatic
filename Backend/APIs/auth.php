<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['username']) || !isset($data['password'])) {
        echo json_encode(['error' => 'Username and password are required']);
        exit();
    }

    $username = $data['username'];
    $password = $data['password'];

    try {
        $stmt = $conn->prepare("SELECT id_usuario as id, nombre, cedula, r.nombre_rol as rol, password_hash as password 
                               FROM tic_usuarios u 
                               JOIN tic_roles r ON u.id_rol = r.id_rol 
                               WHERE correo_electronico = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($password, $user['password'])) {
            // Remove password from response
            unset($user['password']);
            echo json_encode([
                'success' => true,
                'message' => 'Login successful',
                'user' => $user
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid username or password'
            ]);
        }
    } catch(PDOException $e) {
        echo json_encode(['error' => 'Login failed: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'Invalid request method']);
}
?> 