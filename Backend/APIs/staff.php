<?php
require_once 'common.php';

// Función para obtener todo el personal de soporte
function getAllStaff() {
    global $conn;
    try {
        $query = "SELECT u.id_usuario, u.nombre, u.apellido, u.cedula, 
                        u.correo_electronico, r.nombre_rol, u.fecha_creacion, 
                        u.ultima_sesion
                 FROM tic_usuarios u
                 JOIN tic_roles r ON u.id_rol = r.id_rol
                 ORDER BY u.nombre, u.apellido";
        
        $stmt = $conn->query($query);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        writeLog("Obteniendo lista de personal: " . count($result) . " registros encontrados", "staff");
        return $result;
    } catch(PDOException $e) {
        writeLog("Error al obtener personal: " . $e->getMessage(), "staff");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// Función para obtener un miembro del personal por ID
function getStaffMember($id) {
    global $conn;
    try {
        $stmt = $conn->prepare("SELECT u.id_usuario, u.nombre, u.apellido, u.cedula, 
                                      u.correo_electronico, r.nombre_rol, u.fecha_creacion, 
                                      u.ultima_sesion
                               FROM tic_usuarios u
                               JOIN tic_roles r ON u.id_rol = r.id_rol
                               WHERE u.id_usuario = ?");
        $stmt->execute([$id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result) {
            writeLog("Personal encontrado con ID: " . $id, "staff");
            return $result;
        } else {
            writeLog("No se encontró personal con ID: " . $id, "staff");
            http_response_code(404);
            return ['error' => 'Staff member not found'];
        }
    } catch(PDOException $e) {
        writeLog("Error al obtener personal con ID " . $id . ": " . $e->getMessage(), "staff");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// Función para crear un nuevo miembro del personal
function createStaffMember($data) {
    global $conn;
    try {
        writeLog("Intentando crear nuevo personal con datos: " . json_encode($data), "staff");
        
        // Verificar si el correo ya existe
        $stmt = $conn->prepare("SELECT COUNT(*) FROM tic_usuarios WHERE correo_electronico = ?");
        $stmt->execute([$data['correo_electronico']]);
        if ($stmt->fetchColumn() > 0) {
            writeLog("Error: Correo electrónico ya existe: " . $data['correo_electronico'], "staff");
            http_response_code(409);
            return ['error' => 'Email already exists'];
        }

        // Verificar si la cédula ya existe
        $stmt = $conn->prepare("SELECT COUNT(*) FROM tic_usuarios WHERE cedula = ?");
        $stmt->execute([$data['cedula']]);
        if ($stmt->fetchColumn() > 0) {
            writeLog("Error: Cédula ya existe: " . $data['cedula'], "staff");
            http_response_code(409);
            return ['error' => 'ID number already exists'];
        }

        $stmt = $conn->prepare("INSERT INTO tic_usuarios (
            nombre, apellido, cedula, correo_electronico, 
            password_hash, id_rol
        ) VALUES (?, ?, ?, ?, ?, ?)");

        $passwordHash = password_hash($data['password'], PASSWORD_BCRYPT);

        $stmt->execute([
            $data['nombre'],
            $data['apellido'],
            $data['cedula'],
            $data['correo_electronico'],
            $passwordHash,
            $data['id_rol']
        ]);

        $newId = $conn->lastInsertId();
        writeLog("Personal creado exitosamente con ID: " . $newId, "staff");
        http_response_code(201);
        return ['success' => true, 'message' => 'Staff member created successfully', 'id' => $newId];
    } catch(PDOException $e) {
        writeLog("Error al crear personal: " . $e->getMessage(), "staff");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// Función para actualizar un miembro del personal
function updateStaffMember($id, $data) {
    global $conn;
    try {
        writeLog("Intentando actualizar personal ID: " . $id . " con datos: " . json_encode($data), "staff");
        
        $updateFields = [];
        $params = [];

        if (isset($data['nombre'])) {
            $updateFields[] = "nombre = ?";
            $params[] = $data['nombre'];
        }
        if (isset($data['apellido'])) {
            $updateFields[] = "apellido = ?";
            $params[] = $data['apellido'];
        }
        if (isset($data['correo_electronico'])) {
            // Verificar si el nuevo correo ya existe para otro usuario
            $stmt = $conn->prepare("SELECT COUNT(*) FROM tic_usuarios WHERE correo_electronico = ? AND id_usuario != ?");
            $stmt->execute([$data['correo_electronico'], $id]);
            if ($stmt->fetchColumn() > 0) {
                writeLog("Error: Correo electrónico ya existe: " . $data['correo_electronico'], "staff");
                http_response_code(409);
                return ['error' => 'Email already exists'];
            }
            $updateFields[] = "correo_electronico = ?";
            $params[] = $data['correo_electronico'];
        }
        if (isset($data['password'])) {
            $updateFields[] = "password_hash = ?";
            $params[] = password_hash($data['password'], PASSWORD_BCRYPT);
        }
        if (isset($data['id_rol'])) {
            $updateFields[] = "id_rol = ?";
            $params[] = $data['id_rol'];
        }

        if (empty($updateFields)) {
            writeLog("No hay campos para actualizar en personal ID: " . $id, "staff");
            http_response_code(400);
            return ['error' => 'No fields to update'];
        }

        $params[] = $id;
        $query = "UPDATE tic_usuarios SET " . implode(", ", $updateFields) . " WHERE id_usuario = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->execute($params);

        writeLog("Personal ID: " . $id . " actualizado exitosamente", "staff");
        return ['success' => true, 'message' => 'Staff member updated successfully'];
    } catch(PDOException $e) {
        writeLog("Error al actualizar personal ID " . $id . ": " . $e->getMessage(), "staff");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// NUEVO: Función para obtener personal filtrado y paginado
function getStaffFiltered($cedula = '', $page = 1, $perPage = 10) {
    global $conn;
    $offset = ($page - 1) * $perPage;
    $params = [];
    $where = '';
    if ($cedula !== '') {
        $where = 'WHERE u.cedula LIKE ?';
        $params[] = "%$cedula%";
    }
    $query = "SELECT u.id_usuario, u.nombre, u.apellido, u.cedula, 
                     u.correo_electronico, r.nombre_rol, u.fecha_creacion, 
                     u.ultima_sesion
              FROM tic_usuarios u
              JOIN tic_roles r ON u.id_rol = r.id_rol
              $where
              ORDER BY u.nombre, u.apellido
              LIMIT $perPage OFFSET $offset";
    $stmt = $conn->prepare($query);
    $stmt->execute($params);
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Total para paginación
    $countQuery = "SELECT COUNT(*) FROM tic_usuarios u " . ($where ? $where : '');
    $countStmt = $conn->prepare($countQuery);
    $countStmt->execute($params);
    $total = $countStmt->fetchColumn();

    return [
        'success' => true,
        'data' => $result,
        'total' => $total,
        'page' => $page,
        'perPage' => $perPage
    ];
}

// Procesar la solicitud
$method = $_SERVER['REQUEST_METHOD'];
writeLog("Método de solicitud recibido: " . $method, "staff");

switch($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            $data = getStaffMember($_GET['id']);
            echo json_encode(['success' => !isset($data['error']), 'data' => $data, 'error' => $data['error'] ?? null]);
        } else if (isset($_GET['cedula']) || isset($_GET['page'])) {
            $cedula = $_GET['cedula'] ?? '';
            $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
            $perPage = isset($_GET['perPage']) ? intval($_GET['perPage']) : 10;
            $result = getStaffFiltered($cedula, $page, $perPage);
            echo json_encode($result);
        } else {
            $all = getAllStaff();
            echo json_encode(['success' => true, 'data' => $all]);
        }
        break;
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        if ($data) {
            $result = createStaffMember($data);
            echo json_encode($result + ['success' => !isset($result['error'])]);
        } else {
            writeLog("Error: Datos inválidos recibidos en POST", "staff");
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid data']);
        }
        break;
    case 'PUT':
        if (!isset($_GET['id'])) {
            writeLog("Error: ID de personal no proporcionado en PUT", "staff");
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Staff ID required']);
            break;
        }
        $data = json_decode(file_get_contents('php://input'), true);
        if ($data) {
            $result = updateStaffMember($_GET['id'], $data);
            echo json_encode($result + ['success' => !isset($result['error'])]);
        } else {
            writeLog("Error: Datos inválidos recibidos en PUT", "staff");
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid data']);
        }
        break;
    case 'DELETE':
        if (!isset($_GET['id'])) {
            writeLog("Error: ID de personal no proporcionado en DELETE", "staff");
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Staff ID required']);
            break;
        }
        $id = $_GET['id'];
        try {
            $stmt = $conn->prepare("DELETE FROM tic_usuarios WHERE id_usuario = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true, 'message' => 'Staff member deleted']);
        } catch(PDOException $e) {
            writeLog("Error al eliminar personal ID $id: " . $e->getMessage(), "staff");
            http_response_code(500);
            echo json_encode(['success' => false, 'error' => $e->getMessage()]);
        }
        break;
    default:
        writeLog("Método no soportado: " . $method, "staff");
        http_response_code(405);
        echo json_encode(['success' => false, 'error' => 'Method not allowed']);
}
?> 