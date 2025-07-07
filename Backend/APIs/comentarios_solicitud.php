<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

$host = "localhost";
$user = "ducjinsp_sena";
$password = "senaguainia2025";
$dbname = "ducjinsp_demo";

// Activa el reporte de errores SOLO para pruebas
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->exec("SET NAMES utf8");
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => "Connection failed: " . $e->getMessage()]);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['id_solicitud'])) {
    $id = intval($_GET['id_solicitud']);
    $stmt = $conn->prepare("SELECT c.*, u.nombre, u.apellido 
        FROM tic_comentarios_solicitud c 
        JOIN tic_usuarios u ON c.id_usuario_comentario = u.id_usuario
        WHERE c.id_solicitud = :id
        ORDER BY c.fecha_comentario DESC");
    $stmt->execute(['id' => $id]);
    $comentarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($comentarios);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data || !isset($data['id_solicitud'], $data['id_usuario_comentario'], $data['comentario'])) {
        echo json_encode(['success' => false, 'error' => 'Datos incompletos']);
        exit;
    }
    $id_solicitud = intval($data['id_solicitud']);
    $id_usuario = intval($data['id_usuario_comentario']);
    $comentario = $data['comentario'];
    $fecha = date('Y-m-d H:i:s');
    $stmt = $conn->prepare("INSERT INTO tic_comentarios_solicitud (id_solicitud, id_usuario_comentario, comentario, fecha_comentario) VALUES (:id_solicitud, :id_usuario, :comentario, :fecha)");
    $ok = $stmt->execute([
        'id_solicitud' => $id_solicitud,
        'id_usuario' => $id_usuario,
        'comentario' => $comentario,
        'fecha' => $fecha
    ]);
    echo json_encode(['success' => $ok]);
    exit;
}

echo json_encode([]);
exit;