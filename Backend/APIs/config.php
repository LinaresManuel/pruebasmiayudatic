<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Configuración de la base de datos para producción
$host = "localhost";
$user = "u291982824_miayudatic";
$password = "senaguainia2025";
$dbname = "u291982824_miayudatic";

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->exec("SET NAMES utf8");
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => "Connection failed: " . $e->getMessage()]);
    exit();
}
?> 