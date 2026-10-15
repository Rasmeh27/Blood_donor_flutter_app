package com.validei.api.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        String email,

        @NotBlank(message = "La contraseña es obligatoria")
        String password
) {
    // Se recortan los espacios antes de validar el formato del correo
    public LoginRequest {
        email = email == null ? null : email.trim();
    }
}
