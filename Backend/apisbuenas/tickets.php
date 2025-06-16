<?php
require_once 'common.php';

// Función para obtener todos los tickets
function getTickets() {
    global $conn;
    try {
        $query = "SELECT t.*, d.nombre_dependencia, ts.nombre_tipo_servicio, es.nombre_estado,
                        CONCAT(u.nombre, ' ', u.apellido) as personal_asignado
                 FROM tic_solicitudes t
                 LEFT JOIN tic_dependencias d ON t.id_dependencia = d.id_dependencia
                 LEFT JOIN tic_tipos_servicio ts ON t.id_tipo_servicio = ts.id_tipo_servicio
                 LEFT JOIN tic_estados_solicitud es ON t.id_estado = es.id_estado
                 LEFT JOIN tic_usuarios u ON t.id_personal_ti_asignado = u.id_usuario
                 WHERE t.id_estado = 1
                 ORDER BY t.fecha_creacion_registro ASC";
        
        $stmt = $conn->query($query);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        writeLog("Obteniendo tickets: " . count($result) . " registros encontrados", "tickets");
        return $result;
    } catch(PDOException $e) {
        writeLog("Error al obtener tickets: " . $e->getMessage(), "tickets");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// Función para crear un nuevo ticket
function createTicket($data) {
    global $conn;
    try {
        writeLog("Intentando crear ticket con datos: " . json_encode($data), "tickets");
        
        // Validar que todos los campos requeridos estén presentes
        $requiredFields = [
            'fecha_reporte',
            'nombres_solicitante',
            'apellidos_solicitante',
            'correo_institucional_solicitante',
            'numero_contacto_solicitante',
            'descripcion_solicitud',
            'id_dependencia'
        ];
        
        foreach ($requiredFields as $field) {
            if (!isset($data[$field])) {
                writeLog("Error: Campo requerido faltante: $field", "tickets");
                http_response_code(400);
                return ['error' => "Campo requerido faltante: $field"];
            }
        }
        
        $stmt = $conn->prepare("INSERT INTO tic_solicitudes (
            fecha_reporte, nombres_solicitante, apellidos_solicitante,
            correo_institucional_solicitante, numero_contacto_solicitante,
            descripcion_solicitud, id_dependencia, id_estado
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 1)"); // 1 = Estado 'Abierta'

        $params = [
            $data['fecha_reporte'],
            $data['nombres_solicitante'],
            $data['apellidos_solicitante'],
            $data['correo_institucional_solicitante'],
            $data['numero_contacto_solicitante'],
            $data['descripcion_solicitud'],
            $data['id_dependencia']
        ];
        
        writeLog("Ejecutando consulta con parámetros: " . json_encode($params), "tickets");
        $stmt->execute($params);

        $ticketId = $conn->lastInsertId();
        writeLog("Ticket creado exitosamente con ID: " . $ticketId, "tickets");
        return ['success' => true, 'message' => 'Ticket created successfully', 'ticket_id' => $ticketId];
    } catch(PDOException $e) {
        writeLog("Error al crear ticket: " . $e->getMessage(), "tickets");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// Función para actualizar un ticket
function updateTicket($ticketId, $data) {
    global $conn;
    try {
        writeLog("Intentando actualizar ticket ID: " . $ticketId . " con datos: " . json_encode($data), "tickets");
        
        $updateFields = [];
        $params = [];
        
        if (isset($data['id_estado'])) {
            $updateFields[] = "id_estado = ?";
            $params[] = $data['id_estado'];
        }
        if (isset($data['id_tipo_servicio'])) {
            $updateFields[] = "id_tipo_servicio = ?";
            $params[] = $data['id_tipo_servicio'];
        }
        if (isset($data['id_personal_ti_asignado'])) {
            $updateFields[] = "id_personal_ti_asignado = ?";
            $params[] = $data['id_personal_ti_asignado'];
        }
        if (isset($data['fecha_cierre']) && $data['id_estado'] == 3) { // 3 = Cerrada
            $updateFields[] = "fecha_cierre = CURRENT_TIMESTAMP";
        }

        if (empty($updateFields)) {
            writeLog("No hay campos para actualizar en el ticket ID: " . $ticketId, "tickets");
            http_response_code(400);
            return ['error' => 'No fields to update'];
        }

        $query = "UPDATE tic_solicitudes SET " . implode(", ", $updateFields) . " WHERE id_solicitud = ?";
        $params[] = $ticketId;

        $stmt = $conn->prepare($query);
        $stmt->execute($params);

        writeLog("Ticket ID: " . $ticketId . " actualizado exitosamente", "tickets");
        return ['success' => true, 'message' => 'Ticket updated successfully'];
    } catch(PDOException $e) {
        writeLog("Error al actualizar ticket ID: " . $ticketId . ": " . $e->getMessage(), "tickets");
        http_response_code(500);
        return ['error' => $e->getMessage()];
    }
}

// Procesar la solicitud
$method = $_SERVER['REQUEST_METHOD'];
writeLog("Método de solicitud recibido: " . $method, "tickets");

switch($method) {
    case 'GET':
        echo json_encode(getTickets());
        break;
        
    case 'POST':
        $jsonInput = file_get_contents('php://input');
        $data = json_decode($jsonInput, true);
        writeLog("Datos recibidos en POST: " . $jsonInput, "tickets");
        
        if ($data) {
            echo json_encode(createTicket($data));
        } else {
            writeLog("Error: Datos inválidos recibidos en POST", "tickets");
            http_response_code(400);
            echo json_encode(['error' => 'Invalid data']);
        }
        break;
        
    case 'PUT':
        $data = json_decode(file_get_contents('php://input'), true);
        if (isset($_GET['id']) && $data) {
            echo json_encode(updateTicket($_GET['id'], $data));
        } else {
            writeLog("Error: ID de ticket no proporcionado o datos inválidos en PUT", "tickets");
            http_response_code(400);
            echo json_encode(['error' => 'Ticket ID and update data required']);
        }
        break;
        
    default:
        writeLog("Método no soportado: " . $method, "tickets");
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
}
?>