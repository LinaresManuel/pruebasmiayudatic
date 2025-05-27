<?php
require_once 'config.php';

// Get all tickets
function getTickets() {
    global $conn;
    try {
        $stmt = $conn->query("SELECT 
            s.id_solicitud as id,
            s.fecha_reporte,
            s.nombres_solicitante,
            s.apellidos_solicitante,
            s.correo_institucional_solicitante,
            s.numero_contacto_solicitante,
            s.descripcion_solicitud,
            d.nombre_dependencia,
            e.nombre_estado as estado,
            ts.nombre_tipo_servicio as tipo_servicio,
            CONCAT(u.nombre, ' ', u.apellido) as personal_asignado,
            s.fecha_creacion_registro,
            s.fecha_cierre
        FROM tic_solicitudes s
        LEFT JOIN tic_dependencias d ON s.id_dependencia = d.id_dependencia
        LEFT JOIN tic_estados_solicitud e ON s.id_estado = e.id_estado
        LEFT JOIN tic_tipos_servicio ts ON s.id_tipo_servicio = ts.id_tipo_servicio
        LEFT JOIN tic_usuarios u ON s.id_personal_ti_asignado = u.id_usuario
        ORDER BY s.fecha_creacion_registro DESC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        return ['error' => $e->getMessage()];
    }
}

// Create new ticket
function createTicket($data) {
    global $conn;
    try {
        // First get the dependencia ID
        $stmtDep = $conn->prepare("SELECT id_dependencia FROM tic_dependencias WHERE nombre_dependencia = ?");
        $stmtDep->execute([$data['dependencia']]);
        $depId = $stmtDep->fetchColumn();
        
        if (!$depId) {
            return ['error' => 'Dependencia no válida'];
        }

        // Get the estado ID for 'Abierta'
        $stmtEstado = $conn->prepare("SELECT id_estado FROM tic_estados_solicitud WHERE nombre_estado = 'Abierta'");
        $stmtEstado->execute();
        $estadoId = $stmtEstado->fetchColumn();

        $stmt = $conn->prepare("INSERT INTO tic_solicitudes (
            fecha_reporte,
            nombres_solicitante,
            apellidos_solicitante,
            correo_institucional_solicitante,
            numero_contacto_solicitante,
            descripcion_solicitud,
            id_dependencia,
            id_estado
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        
        $stmt->execute([
            $data['fecha_reporte'],
            $data['nombres'],
            $data['apellidos'],
            $data['correo'],
            $data['numero_contacto'],
            $data['descripcion'],
            $depId,
            $estadoId
        ]);
        
        return ['success' => true, 'id' => $conn->lastInsertId()];
    } catch(PDOException $e) {
        return ['error' => $e->getMessage()];
    }
}

// Update ticket
function updateTicket($id, $data) {
    global $conn;
    try {
        $updateFields = [];
        $params = [];
        
        if (isset($data['estado'])) {
            $stmtEstado = $conn->prepare("SELECT id_estado FROM tic_estados_solicitud WHERE nombre_estado = ?");
            $stmtEstado->execute([$data['estado']]);
            $estadoId = $stmtEstado->fetchColumn();
            if ($estadoId) {
                $updateFields[] = "id_estado = ?";
                $params[] = $estadoId;
            }
        }

        if (isset($data['tipo_servicio'])) {
            $stmtTipo = $conn->prepare("SELECT id_tipo_servicio FROM tic_tipos_servicio WHERE nombre_tipo_servicio = ?");
            $stmtTipo->execute([$data['tipo_servicio']]);
            $tipoId = $stmtTipo->fetchColumn();
            if ($tipoId) {
                $updateFields[] = "id_tipo_servicio = ?";
                $params[] = $tipoId;
            }
        }

        if (isset($data['personal_asignado'])) {
            $updateFields[] = "id_personal_ti_asignado = ?";
            $params[] = $data['personal_asignado'];
        }

        if (isset($data['fecha_cierre'])) {
            $updateFields[] = "fecha_cierre = ?";
            $params[] = $data['fecha_cierre'];
        }
        
        if (empty($updateFields)) {
            return ['error' => 'No hay campos para actualizar'];
        }

        $params[] = $id;
        $updateQuery = "UPDATE tic_solicitudes SET " . implode(', ', $updateFields) . " WHERE id_solicitud = ?";
        
        $stmt = $conn->prepare($updateQuery);
        $stmt->execute($params);
        
        return ['success' => true];
    } catch(PDOException $e) {
        return ['error' => $e->getMessage()];
    }
}

// Get ticket details
function getTicketDetails($id) {
    global $conn;
    try {
        $stmt = $conn->prepare("SELECT 
            s.id_solicitud as id,
            s.fecha_reporte,
            s.nombres_solicitante,
            s.apellidos_solicitante,
            s.correo_institucional_solicitante,
            s.numero_contacto_solicitante,
            s.descripcion_solicitud,
            d.nombre_dependencia,
            e.nombre_estado as estado,
            ts.nombre_tipo_servicio as tipo_servicio,
            CONCAT(u.nombre, ' ', u.apellido) as personal_asignado,
            s.fecha_creacion_registro,
            s.fecha_cierre
        FROM tic_solicitudes s
        LEFT JOIN tic_dependencias d ON s.id_dependencia = d.id_dependencia
        LEFT JOIN tic_estados_solicitud e ON s.id_estado = e.id_estado
        LEFT JOIN tic_tipos_servicio ts ON s.id_tipo_servicio = ts.id_tipo_servicio
        LEFT JOIN tic_usuarios u ON s.id_personal_ti_asignado = u.id_usuario
        WHERE s.id_solicitud = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
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
            $response = getTicketDetails($_GET['id']);
        } else {
            $response = getTickets();
        }
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $response = createTicket($data);
        break;
        
    case 'PUT':
        $data = json_decode(file_get_contents('php://input'), true);
        if (isset($data['id'])) {
            $id = $data['id'];
            $response = updateTicket($id, $data);
        } else {
            $response = ['error' => 'Ticket ID is required'];
        }
        break;
        
    default:
        $response = ['error' => 'Invalid request method'];
}

echo json_encode($response);
?> 