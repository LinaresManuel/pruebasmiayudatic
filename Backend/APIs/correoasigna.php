<?php
require_once 'common.php';
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'PHPMailer/Exception.php';
require 'PHPMailer/PHPMailer.php';
require 'PHPMailer/SMTP.php';

header('Content-Type: application/json');

// Recibir datos por POST
$data = json_decode(file_get_contents('php://input'), true);

$id_solicitud = $data['id_solicitud'] ?? null;
$id_personal_ti_asignado = $data['id_personal_ti_asignado'] ?? null;
$tipo_servicio = $data['tipo_servicio'] ?? null;

if (!$id_solicitud || !$id_personal_ti_asignado) {
    echo json_encode(['success' => false, 'message' => 'Faltan datos requeridos']);
    exit;
}

try {
    // Obtener información del ticket y del técnico asignado
    $stmt = $conn->prepare("
        SELECT 
            t.id_solicitud,
            t.fecha_reporte,
            t.nombres_solicitante,
            t.apellidos_solicitante,
            t.correo_institucional_solicitante,
            t.numero_contacto_solicitante,
            t.descripcion_solicitud,
            d.nombre_dependencia,
            ts.nombre_tipo_servicio,
            u.nombre as nombre_tecnico,
            u.apellido as apellido_tecnico,
            u.correo_electronico as correo_tecnico
        FROM tic_solicitudes t
        LEFT JOIN tic_dependencias d ON t.id_dependencia = d.id_dependencia
        LEFT JOIN tic_tipos_servicio ts ON t.id_tipo_servicio = ts.id_tipo_servicio
        LEFT JOIN tic_usuarios u ON t.id_personal_ti_asignado = u.id_usuario
        WHERE t.id_solicitud = ? AND t.id_personal_ti_asignado = ?
    ");
    
    $stmt->execute([$id_solicitud, $id_personal_ti_asignado]);
    $ticket = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$ticket) {
        echo json_encode(['success' => false, 'message' => 'Ticket o técnico no encontrado']);
        exit;
    }
    
    // Calcular días abierta
    $fecha_reporte = new DateTime($ticket['fecha_reporte']);
    $hoy = new DateTime();
    $dias_abierta = $fecha_reporte->diff($hoy)->days;
    
    $mail = new PHPMailer(true);
    
    // Configuración del servidor SMTP
    $mail->SMTPDebug = 0;
    $mail->isSMTP();
    $mail->Host       = 'mail.ducjin.space';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'miayudatic@ducjin.space';
    $mail->Password   = 'Adso_2025**/';
    $mail->SMTPSecure = 'ssl';
    $mail->Port       = 465;
    
    // Configuración de idioma y codificación
    $mail->CharSet = 'UTF-8';
    $mail->setLanguage('es');
    
    // Destinatario
    $mail->setFrom('miayudatic@ducjin.space', 'MiAyudaTic');
    $mail->addAddress($ticket['correo_tecnico']);
    
    // Contenido del correo
    $mail->isHTML(true);
    $mail->Subject = 'Nueva asignación de ticket - Mi Ayuda Tic Regional Guainía';
    $mail->Body    = "
        <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;'>
            <div style='text-align: center; margin-bottom: 30px;'>
                <img src='https://ducjin.space/miayudatic/assets/sena_logo.png' alt='Logo SENA' style='height: 80px; margin-bottom: 10px;' />
                <h2 style='color: #2c3e50; margin-bottom: 20px;'>Nueva asignación de ticket</h2>
            </div>
            
            <div style='background-color: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #28a745;'>
                <p style='margin: 0; color: #155724; font-weight: bold;'>Estimado/a {$ticket['nombre_tecnico']} {$ticket['apellido_tecnico']},</p>
                <p style='margin: 10px 0 0 0; color: #155724;'>Se le ha asignado un nuevo ticket de soporte técnico.</p>
            </div>
            
            <table style='width: 100%; border-collapse: collapse; margin-bottom: 30px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);'>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold; width: 40%;'>Ticket N°:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['id_solicitud']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Fecha del reporte:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['fecha_reporte']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Días abierta:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$dias_abierta} día(s)</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Solicitante:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['nombres_solicitante']} {$ticket['apellidos_solicitante']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Correo del solicitante:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['correo_institucional_solicitante']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Contacto:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['numero_contacto_solicitante']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Dependencia:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['nombre_dependencia']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Tipo de servicio:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$ticket['nombre_tipo_servicio']}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; background-color: #f8f9fa; font-weight: bold; vertical-align: top;'>Descripción:</td>
                    <td style='padding: 15px;'>{$ticket['descripcion_solicitud']}</td>
                </tr>
            </table>
            
            <div style='background-color: #fff3cd; padding: 20px; border-radius: 8px; margin-bottom: 30px; border-left: 4px solid #ffc107;'>
                <p style='margin: 0; color: #856404; font-weight: bold;'>Acción requerida:</p>
                <p style='margin: 10px 0 0 0; color: #856404;'>Por favor, proceda a atender esta solicitud de soporte técnico lo antes posible.</p>
            </div>
            
            <div style='text-align: center; padding-top: 20px; border-top: 1px solid #e0e0e0;'>
                <p style='color: #2c3e50; font-weight: bold; margin: 0;'>MiAyudaTic - SENA Regional Guainía</p>
                <p style='color: #6c757d; margin: 5px 0 0 0; font-size: 12px;'>Este es un correo automático, por favor no responda a este mensaje.</p>
            </div>
        </div>
    ";
    
    $mail->send();
    
    // Registrar en el historial
    $stmt = $conn->prepare("
        INSERT INTO tic_historial_solicitud (id_solicitud, id_usuario_cambio, tipo_cambio, detalle_cambio)
        VALUES (?, ?, 'Asignación Realizada', ?)
    ");
    $detalle = "Ticket asignado a {$ticket['nombre_tecnico']} {$ticket['apellido_tecnico']}";
    $stmt->execute([$id_solicitud, $id_personal_ti_asignado, $detalle]);
    
    echo json_encode(['success' => true, 'message' => 'Correo de asignación enviado correctamente']);
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => "Error al enviar el correo: {$mail->ErrorInfo}"]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => "Error en la base de datos: {$e->getMessage()}"]);
}
?> 