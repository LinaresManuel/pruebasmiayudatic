<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Incluir archivo de conexión
require_once 'conexion.php';

try {
    // Preparar la consulta SQL para obtener las solicitudes cerradas
    $sql = "SELECT 
                t.id,
                t.fecha_reporte,
                t.nombres_solicitante,
                t.apellidos_solicitante,
                t.correo_solicitante,
                t.numero_contacto,
                t.dependencia,
                t.descripcion,
                t.fecha_creacion,
                t.fecha_cierre,
                e.nombre_estado as estado,
                ts.nombre_tipo_servicio as tipo_servicio,
                CONCAT(u.nombres, ' ', u.apellidos) as personal_asignado
            FROM tickets t
            LEFT JOIN estados e ON t.id_estado = e.id
            LEFT JOIN tipos_servicio ts ON t.id_tipo_servicio = ts.id
            LEFT JOIN usuarios u ON t.id_personal_ti_asignado = u.id
            WHERE e.nombre_estado = 'Cerrada'
            ORDER BY t.fecha_cierre DESC";

    // Ejecutar la consulta
    $stmt = $conn->prepare($sql);
    $stmt->execute();
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Verificar si se encontraron resultados
    if (count($result) > 0) {
        // Devolver los resultados como JSON
        echo json_encode($result);
    } else {
        // Si no hay resultados, devolver un array vacío
        echo json_encode([]);
    }

} catch(PDOException $e) {
    // En caso de error, devolver un mensaje de error
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'message' => 'Error al obtener las solicitudes cerradas: ' . $e->getMessage()
    ]);
}

// Cerrar la conexión
$conn = null;
?> 