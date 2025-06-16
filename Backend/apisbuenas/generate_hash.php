<?php
$password = "123";
$hash = password_hash($password, PASSWORD_BCRYPT);
echo "Password: $password\n";
echo "Hash generado: $hash\n";
echo "Verificación: " . (password_verify($password, $hash) ? "Exitosa" : "Fallida") . "\n";
?> 