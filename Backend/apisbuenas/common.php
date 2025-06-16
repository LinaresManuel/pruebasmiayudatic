<?php
// Configuración de headers CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Manejar solicitud OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Incluir configuración de la base de datos
require_once 'config.php';

// Función común para escribir logs
function writeLog($message, $category = 'general') {
    $logDir = __DIR__ . '/logs';
    if (!file_exists($logDir)) {
        mkdir($logDir, 0777, true);
    }
    
    $logFile = $logDir . '/api.log';
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] [$category] $message\n";
    
    // Asegurar que el archivo de log existe y es escribible
    if (!file_exists($logFile)) {
        touch($logFile);
        chmod($logFile, 0666);
    }
    
    file_put_contents($logFile, $logMessage, FILE_APPEND);
}
?> 