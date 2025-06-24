<?php
require_once 'common.php';
require 'PHPMailer/Exception.php';
require 'PHPMailer/PHPMailer.php';
require 'PHPMailer/SMTP.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

$id_solicitud = $data['id_solicitud'] ?? null;
$descripcion_solucion = $data['descripcion_solucion'] ?? null;

if (!$id_solicitud || !$descripcion_solucion) {
    echo json_encode(['success' => false, 'message' => 'Faltan datos requeridos']);
    exit;
}

// Manejo robusto de errores para siempre devolver JSON
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/cerrar_caso_y_enviar_correo_error.log');
error_reporting(E_ALL);

set_exception_handler(function($e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Excepción no controlada: ' . $e->getMessage()]);
    exit;
});

set_error_handler(function($errno, $errstr, $errfile, $errline) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => "Error PHP: $errstr en $errfile:$errline"]);
    exit;
});

try {
    // 2. Obtener datos del ticket y del personal asignado
    $stmt = $conn->prepare("
        SELECT 
            s.correo_institucional_solicitante AS correo_solicitante,
            s.nombres_solicitante,
            s.apellidos_solicitante,
            s.descripcion_solicitud,
            s.fecha_reporte,
            u.correo_electronico AS correo_personal
        FROM tic_solicitudes s
        LEFT JOIN tic_usuarios u ON s.id_personal_ti_asignado = u.id_usuario
        WHERE s.id_solicitud = ?
        LIMIT 1
    ");
    $stmt->execute([$id_solicitud]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo json_encode(['success' => false, 'message' => 'Solicitud no encontrada']);
        exit;
    }

    $correos = [];
    if (!empty($row['correo_solicitante'])) $correos[] = $row['correo_solicitante'];
    if (!empty($row['correo_personal'])) $correos[] = $row['correo_personal'];

    // 3. Actualizar el ticket como cerrado
    $stmtUpdate = $conn->prepare("
        UPDATE tic_solicitudes
        SET id_estado = 3, fecha_cierre = NOW(), descripcion_solucion = ?
        WHERE id_solicitud = ?
    ");
    $stmtUpdate->execute([$descripcion_solucion, $id_solicitud]);

    // 4. Enviar correo a ambos destinatarios
    $mail = new PHPMailer\PHPMailer\PHPMailer(true);
    $mail->isSMTP();
    $mail->Host       = 'mail.ducjin.space';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'miayudatic@ducjin.space';
    $mail->Password   = 'Adso_2025**/';
    $mail->SMTPSecure = 'ssl';
    $mail->Port       = 465;
    $mail->CharSet = 'UTF-8';
    $mail->setLanguage('es');
    $mail->setFrom('miayudatic@ducjin.space', 'MiAyudaTic');

    foreach ($correos as $correo) {
        $mail->addAddress($correo);
    }

    $mail->isHTML(true);
    $mail->Subject = 'Cierre de caso - MiAyudaTic';
    $mail->Body    = "
        <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;'>
            <h2 style='color: #2c3e50;'>El caso N° {$id_solicitud} ha sido cerrado</h2>
            <p><strong>Solicitante:</strong> {$row['nombres_solicitante']} {$row['apellidos_solicitante']}</p>
            <p><strong>Fecha de reporte:</strong> {$row['fecha_reporte']}</p>
            <p><strong>Descripción de la solicitud:</strong> {$row['descripcion_solicitud']}</p>
            <p><strong>Solución registrada:</strong> {$descripcion_solucion}</p>
            <br>
            <p>Gracias por usar MiAyudaTic - SENA Regional Guainía.</p>
        </div>
    ";

    $mail->send();

    echo json_encode(['success' => true, 'message' => 'Caso cerrado y correos enviados correctamente']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}