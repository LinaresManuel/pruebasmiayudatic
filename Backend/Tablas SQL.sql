-- DDL para la Base de Datos del Sistema de Gestión de Solicitudes de Soporte

-- 1. Crear la Base de Datos (si aún no existe)
-- Puedes cambiar 'db_soporte' por el nombre que prefieras para tu base de datos
CREATE DATABASE IF NOT EXISTS `u291982824_miayudatic` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Seleccionar la base de datos para trabajar en ella
USE `u291982824_miayudatic`;

-- 2. Tabla 'tic_dependencias'
-- Esta tabla almacenará las diferentes dependencias (Emprendimiento, Formación, Bienestar, etc.)
CREATE TABLE IF NOT EXISTS `tic_dependencias` (
    `id_dependencia` INT AUTO_INCREMENT PRIMARY KEY,
    `nombre_dependencia` VARCHAR(100) NOT NULL UNIQUE
);

-- Insertar algunas dependencias de ejemplo
INSERT INTO `tic_dependencias` (`nombre_dependencia`) VALUES
('Emprendimiento'),
('Formación'),
('Bienestar'),
('Almacén'),
('Grupo mixto'),
('TIC');

-- 3. Tabla 'tic_estados_solicitud'
-- Para gestionar el estado de cada solicitud (Abierta, Cerrada, En Proceso, etc.)
CREATE TABLE IF NOT EXISTS `tic_estados_solicitud` (
    `id_estado` INT AUTO_INCREMENT PRIMARY KEY,
    `nombre_estado` VARCHAR(50) NOT NULL UNIQUE
);

-- Insertar los estados iniciales
INSERT INTO `tic_estados_solicitud` (`nombre_estado`) VALUES
('Abierta'),
('En Proceso'),
('Cerrada');

-- 4. Tabla 'tic_tipos_servicio'
-- Para diferenciar si la solicitud es un 'Servicio' o un 'Incidente'
CREATE TABLE IF NOT EXISTS `tic_tipos_servicio` (
    `id_tipo_servicio` INT AUTO_INCREMENT PRIMARY KEY,
    `nombre_tipo_servicio` VARCHAR(50) NOT NULL UNIQUE
);

-- Insertar los tipos de servicio
INSERT INTO `tic_tipos_servicio` (`nombre_tipo_servicio`) VALUES
('Servicio'),
('Incidente');

-- 5. Tabla 'tic_roles'
-- Para gestionar los roles del personal de soporte (Técnico, Administrador, etc.)
CREATE TABLE IF NOT EXISTS `tic_roles` (
    `id_rol` INT AUTO_INCREMENT PRIMARY KEY,
    `nombre_rol` VARCHAR(50) NOT NULL UNIQUE
);

-- Insertar roles de ejemplo
INSERT INTO `tic_roles` (`nombre_rol`) VALUES
('Técnico'),
('Administrador'),
('Coordinador');


-- 6. Tabla 'tic_usuarios' (Personal de Soporte)
-- Almacena las credenciales y datos del personal de TI
CREATE TABLE IF NOT EXISTS `tic_usuarios` (
    `id_usuario` INT AUTO_INCREMENT PRIMARY KEY,
    `nombre` VARCHAR(100) NOT NULL,
    `apellido` VARCHAR(100) NOT NULL,
    `cedula` VARCHAR(20) NOT NULL UNIQUE,
    `correo_electronico` VARCHAR(100) NOT NULL UNIQUE, -- Correo para inicio de sesión
    `password_hash` VARCHAR(255) NOT NULL, -- Almacena el hash de la contraseña (NUNCA la contraseña en texto plano)
    `id_rol` INT NOT NULL,
    `fecha_creacion` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `ultima_sesion` TIMESTAMP NULL,
    FOREIGN KEY (`id_rol`) REFERENCES `tic_roles`(`id_rol`)
);

-- Consideraciones para 'tic_usuarios':
-- - 'password_hash': Es crucial usar una función de hashing segura (ej. bcrypt) para almacenar las contraseñas.
--   La contraseña en texto plano nunca debe ser almacenada.

-- 7. Tabla 'tic_solicitudes'
-- Aquí se almacenan los datos de cada solicitud de soporte
CREATE TABLE IF NOT EXISTS `tic_solicitudes` (
    `id_solicitud` INT AUTO_INCREMENT PRIMARY KEY,
    `fecha_reporte` DATE NOT NULL, -- Fecha en que el usuario reporta
    `nombres_solicitante` VARCHAR(100) NOT NULL,
    `apellidos_solicitante` VARCHAR(100) NOT NULL,
    `correo_institucional_solicitante` VARCHAR(100) NOT NULL,
    `numero_contacto_solicitante` VARCHAR(20) NOT NULL,
    `descripcion_solicitud` TEXT NOT NULL,
    `id_dependencia` INT NOT NULL,
    `fecha_creacion_registro` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Fecha y hora real de creación del registro en la DB
    `id_estado` INT NOT NULL DEFAULT 1, -- Por defecto 'Abierta' (asumiendo id_estado 1 = Abierta)
    `id_tipo_servicio` INT NULL, -- Puede ser NULL hasta que el personal de TI lo asigne
    `id_personal_ti_asignado` INT NULL, -- ID del usuario de TI asignado, NULL si no ha sido asignado
    `fecha_cierre` DATETIME NULL, -- Se llena al cerrar la solicitud

    -- Claves Foráneas
    FOREIGN KEY (`id_dependencia`) REFERENCES `tic_dependencias`(`id_dependencia`),
    FOREIGN KEY (`id_estado`) REFERENCES `tic_estados_solicitud`(`id_estado`),
    FOREIGN KEY (`id_tipo_servicio`) REFERENCES `tic_tipos_servicio`(`id_tipo_servicio`),
    FOREIGN KEY (`id_personal_ti_asignado`) REFERENCES `tic_usuarios`(`id_usuario`)
);

-- 8. (Opcional) Tabla 'tic_historial_solicitud'
-- Para registrar cambios importantes en el estado o asignación de una solicitud
CREATE TABLE IF NOT EXISTS `tic_historial_solicitud` (
    `id_historial` INT AUTO_INCREMENT PRIMARY KEY,
    `id_solicitud` INT NOT NULL,
    `id_usuario_cambio` INT NULL, -- Quien realizó el cambio (personal de TI)
    `tipo_cambio` VARCHAR(100) NOT NULL, -- Ej: 'Estado Actualizado', 'Asignación Realizada'
    `detalle_cambio` TEXT, -- Ej: 'De Abierta a En Proceso', 'Asignado a Juan Pérez'
    `fecha_cambio` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`id_solicitud`) REFERENCES `tic_solicitudes`(`id_solicitud`),
    FOREIGN KEY (`id_usuario_cambio`) REFERENCES `tic_usuarios`(`id_usuario`)
);

-- 9. (Opcional) Tabla 'tic_comentarios_solicitud'
-- Para permitir que el personal de TI añada comentarios a las solicitudes
CREATE TABLE IF NOT EXISTS `tic_comentarios_solicitud` (
    `id_comentario` INT AUTO_INCREMENT PRIMARY KEY,
    `id_solicitud` INT NOT NULL,
    `id_usuario_comentario` INT NOT NULL, -- Quién hizo el comentario (personal de TI)
    `comentario` TEXT NOT NULL,
    `fecha_comentario` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`id_solicitud`) REFERENCES `tic_solicitudes`(`id_solicitud`),
    FOREIGN KEY (`id_usuario_comentario`) REFERENCES `tic_usuarios`(`id_usuario`)
);