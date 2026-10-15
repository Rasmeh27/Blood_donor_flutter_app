package com.validei.api.common.exception;

// Mismo mensaje para código incorrecto, vencido, usado o correo inexistente: no revela cuál fue el caso
public class InvalidResetCodeException extends RuntimeException {

    public InvalidResetCodeException() {
        super("El código es inválido o ha expirado");
    }
}
