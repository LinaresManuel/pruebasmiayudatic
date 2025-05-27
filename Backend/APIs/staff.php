<?php
require_once 'config.php';

// Get all staff members
function getAllStaff() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT 
            u.id_usuario as id,
            CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
            u.cedula,
            r.nombre_rol as rol,
            u.correo_electronico as username
        FROM tic_usuarios u
        JOIN tic_roles r ON u.id_rol = r.id_rol");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        return ['error' => $e->getMessage()];
    }
}

// Get staff member by ID
function getStaffById($id) {
    global $conn;
    try {
        $stmt = $conn->prepare("SELECT 
            u.id_usuario as id,
            u.nombre,
            u.apellido,
            u.cedula,
            r.nombre_rol as rol,
            u.correo_electronico as username
        FROM tic_usuarios u
        JOIN tic_roles r ON u.id_rol = r.id_rol
        WHERE u.id_usuario = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        return ['error' => $e->getMessage()];
    }
}

// Update staff member
function updateStaff($id, $data) {
    global $conn;
    try {
        $updateFields = [];
        $params = [];
        
        // Map fields to database columns
        $fieldMap = [
            'nombre' => 'nombre',
            'apellido' => 'apellido',
            'cedula' => 'cedula',
            'username' => 'correo_electronico',
            'rol' => 'id_rol'
        ];
        
        foreach ($data as $key => $value) {
            if (isset($fieldMap[$key])) {
                if ($key === 'rol') {
                    // Get role ID from role name
                    $stmtRole = $conn->prepare("SELECT id_rol FROM tic_roles WHERE nombre_rol = ?");
                    $stmtRole->execute([$value]);
                    $roleId = $stmtRole->fetchColumn();
                    if ($roleId) {
                        $updateFields[] = "id_rol = ?";
                        $params[] = $roleId;
                    }
                } else {
                    $updateFields[] = $fieldMap[$key] . " = ?";
                    $params[] = $value;
                }
            }
        }
        
        // Handle password update separately if provided
        if (isset($data['password']) && !empty($data['password'])) {
            $updateFields[] = "password_hash = ?";
            $params[] = password_hash($data['password'], PASSWORD_DEFAULT);
        }
        
        if (empty($updateFields)) {
            return ['error' => 'No hay campos para actualizar'];
        }

        $params[] = $id;
        $updateQuery = "UPDATE tic_usuarios SET " . implode(', ', $updateFields) . " WHERE id_usuario = ?";
        
        $stmt = $conn->prepare($updateQuery);
        $stmt->execute($params);
        
        return ['success' => true];
    } catch(PDOException $e) {
        return ['error' => $e->getMessage()];
    }
}

// Handle requests
$method = $_SERVER['REQUEST_METHOD'];
$response = [];

switch ($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            $response = getStaffById($_GET['id']);
        } else {
            $response = getAllStaff();
        }
        break;
        
    case 'PUT':
        $data = json_decode(file_get_contents('php://input'), true);
        if (isset($data['id'])) {
            $id = $data['id'];
            $response = updateStaff($id, $data);
        } else {
            $response = ['error' => 'Staff ID is required'];
        }
        break;
        
    default:
        $response = ['error' => 'Invalid request method'];
}

echo json_encode($response);
?> 