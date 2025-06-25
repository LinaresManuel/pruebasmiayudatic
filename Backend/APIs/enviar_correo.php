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

$correo_usuario = $data['correo_usuario'] ?? null;
$fecha_reporte = $data['fecha_reporte'] ?? null;
$id_solicitud = $data['id_solicitud'] ?? null;
$descripcion = $data['descripcion'] ?? null;

if (!$correo_usuario || !$fecha_reporte || !$id_solicitud || !$descripcion) {
    echo json_encode(['success' => false, 'message' => 'Faltan datos requeridos']);
    exit;
}

$mail = new PHPMailer(true);

try {
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
    $mail->addAddress($correo_usuario);

    // Contenido del correo
    $mail->isHTML(true);
    $mail->Subject = 'Confirmación de soporte solicitado - Mi Ayuda Tic Regional Guainía';
    $mail->Body    = "
        <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;'>
            <div style='text-align: center; margin-bottom: 30px;'>
                <img src='https://ducjin.space/miayudatic/assets/sena_logo.png' alt='Logo SENA' style='height: 80px; margin-bottom: 10px;' />
                <h2 style='color: #2c3e50; margin-bottom: 20px;'>¡Tu solicitud de soporte ha sido registrada!</h2>
            </div>
            
            <table style='width: 100%; border-collapse: collapse; margin-bottom: 30px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);'>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold; width: 40%;'>Ticket de soporte N°:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$id_solicitud}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0; background-color: #f8f9fa; font-weight: bold;'>Fecha del reporte:</td>
                    <td style='padding: 15px; border-bottom: 1px solid #e0e0e0;'>{$fecha_reporte}</td>
                </tr>
                <tr>
                    <td style='padding: 15px; background-color: #f8f9fa; font-weight: bold; vertical-align: top;'>Descripción:</td>
                    <td style='padding: 15px;'>{$descripcion}</td>
                </tr>
            </table>

            <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px;'>
                <p style='margin: 0; color: #2c3e50;'>Gracias por contactarnos.</p>
                <p style='margin: 15px 0 0 0; color: #2c3e50;'>Nuestro equipo de soporte en sitio pronto se comunicará con usted para la atención y solución de su requerimiento.</p>
            </div>

            <div style='text-align: center; padding-top: 20px; border-top: 1px solid #e0e0e0;'>
                <p style='color: #2c3e50; font-weight: bold; margin: 0;'>MiAyudaTic - SENA Regional Guainía</p>
            </div>
        </div>
    ";

    $mail->send();
    echo json_encode(['success' => true, 'message' => 'Correo enviado correctamente']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => "Error al enviar el correo: {$mail->ErrorInfo}"]);
}