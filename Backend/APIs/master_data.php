<?php
require_once 'common.php';

function getDependencies() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_dependencia, nombre_dependencia FROM tic_dependencias ORDER BY nombre_dependencia");
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        writeLog("Obteniendo dependencias: " . count($result) . " registros encontrados", "master_data");
        return $result;
    } catch(PDOException $e) {
        writeLog("Error al obtener dependencias: " . $e->getMessage(), "master_data");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

function getServiceTypes() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_tipo_servicio, nombre_tipo_servicio FROM tic_tipos_servicio ORDER BY nombre_tipo_servicio");
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        writeLog("Obteniendo tipos de servicio: " . count($result) . " registros encontrados", "master_data");
        return $result;
    } catch(PDOException $e) {
        writeLog("Error al obtener tipos de servicio: " . $e->getMessage(), "master_data");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

function getSupportStaff() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_usuario, CONCAT(nombre, ' ', apellido) as nombre_completo FROM tic_usuarios ORDER BY nombre");
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        writeLog("Obteniendo personal de soporte: " . count($result) . " registros encontrados", "master_data");
        return $result;
    } catch(PDOException $e) {
        writeLog("Error al obtener personal de soporte: " . $e->getMessage(), "master_data");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

function getRoles() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT id_rol, nombre_rol FROM tic_roles ORDER BY nombre_rol");
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        writeLog("Obteniendo roles: " . count($result) . " registros encontrados", "master_data");
        return $result;
    } catch(PDOException $e) {
        writeLog("Error al obtener roles: " . $e->getMessage(), "master_data");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

$action = $_GET['action'] ?? '';
writeLog("Acción solicitada: " . $action, "master_data");

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
    case 'roles':
        echo json_encode(getRoles());
        break;
    default:
        writeLog("Acción inválida solicitada: " . $action, "master_data");
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
}
?> 