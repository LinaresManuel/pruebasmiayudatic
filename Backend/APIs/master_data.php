<?php
require_once 'config.php';

// Handle CORS preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function getDependencies() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_dependencia, nombre_dependencia FROM tic_dependencias ORDER BY nombre_dependencia");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

function getServiceTypes() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_tipo_servicio, nombre_tipo_servicio FROM tic_tipos_servicio ORDER BY nombre_tipo_servicio");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

function getSupportStaff() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_usuario, CONCAT(nombre, ' ', apellido) as nombre_completo FROM tic_usuarios ORDER BY nombre");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

$action = $_GET['action'] ?? '';

switch($action) {
    case 'dependencies':
        echo json_encode(getDependencies());
        break;
    case 'service-types':
        echo json_encode(getServiceTypes());
        break;
    case 'support-staff':
        echo json_encode(getSupportStaff());
        break;
    default:
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
}
?> 