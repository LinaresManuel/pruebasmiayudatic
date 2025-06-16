<?php
require_once 'common.php';

// Contraseña de prueba
$password = "password123";

// Generar hash
$hash = password_hash($password, PASSWORD_BCRYPT);
writeLog("Test - Contraseña original: $password", 'test');
writeLog("Test - Hash generado (length: " . strlen($hash) . "): $hash", 'test');

// Verificar la contraseña
$verification = password_verify($password, $hash);
writeLog("Test - Verificación: " . ($verification ? "EXITOSA" : "FALLIDA"), 'test');

// Probar con un hash existente de la base de datos
try {
    $stmt = $conn->prepare("SELECT password_hash FROM tic_usuarios WHERE correo_electronico = ?");
    $stmt->execute(['ana.gomez@example.com']);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result) {
        $dbHash = $result['password_hash'];
        writeLog("Test - Hash en DB (length: " . strlen($dbHash) . "): $dbHash", 'test');
        writeLog("Test - Verificación con hash de DB: " . (password_verify($password, $dbHash) ? "EXITOSA" : "FALLIDA"), 'test');
    } else {
        writeLog("Test - Usuario no encontrado en la base de datos", 'test');
    }
} catch(PDOException $e) {
    writeLog("Test - Error: " . $e->getMessage(), 'test');
}

echo json_encode(['message' => 'Test completed, check logs']);
?> 