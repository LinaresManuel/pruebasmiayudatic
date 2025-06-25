<?php
require_once 'common.php';
header('Content-Type: application/json');
$data = json_decode(file_get_contents('php://input'), true);
if (!isset($data['password'])) {
    echo json_encode(['success' => false, 'error' => 'No password provided']);
    exit;
}
$password = $data['password'];
$hash = password_hash($password, PASSWORD_BCRYPT);
echo json_encode([
    'success' => true,
    'hash' => $hash
]);
?>