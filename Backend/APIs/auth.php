<?php
require_once 'common.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    writeLog("Datos recibidos: " . json_encode($data), 'auth');
    
    if (!isset($data['username']) || !isset($data['password'])) {
        writeLog("Error: Faltan credenciales", 'auth');
        http_response_code(400);
        echo json_encode(['error' => 'Username and password are required']);
        exit();
    }

    $username = $data['username'];
    $password = $data['password'];
    
    writeLog("Intentando login con usuario: $username", 'auth');

    try {
        $stmt = $conn->prepare("SELECT u.id_usuario as id, u.nombre, u.apellido, u.cedula, u.correo_electronico, r.nombre_rol as rol, u.fecha_creacion, u.ultima_sesion, u.password_hash as password 
                               FROM tic_usuarios u 
                               JOIN tic_roles r ON u.id_rol = r.id_rol 
                               WHERE u.correo_electronico = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user) {
            writeLog("Usuario encontrado en la base de datos", 'auth');
            
            $storedHash = $user['password'];
            writeLog("Hash almacenado (length: " . strlen($storedHash) . "): " . $storedHash, 'auth');
            writeLog("Contraseña recibida (length: " . strlen($password) . "): " . $password, 'auth');
            
            if (password_verify($password, $storedHash)) {
                writeLog("Verificación de contraseña exitosa", 'auth');
                unset($user['password']);
                echo json_encode([
                    'success' => true,
                    'message' => 'Login successful',
                    'user' => $user
                ]);
            } else {
                writeLog("Verificación de contraseña fallida", 'auth');
                http_response_code(401);
                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid username or password'
                ]);
            }
        } else {
            writeLog("Usuario no encontrado en la base de datos", 'auth');
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid username or password'
            ]);
        }
    } catch(PDOException $e) {
        writeLog("Error de base de datos: " . $e->getMessage(), 'auth');
        http_response_code(500);
        echo json_encode(['error' => 'Login failed: ' . $e->getMessage()]);
    }
} else {
    writeLog("Método de solicitud inválido: " . $_SERVER['REQUEST_METHOD'], 'auth');
    http_response_code(405);
    echo json_encode(['error' => 'Invalid request method']);
}
?>