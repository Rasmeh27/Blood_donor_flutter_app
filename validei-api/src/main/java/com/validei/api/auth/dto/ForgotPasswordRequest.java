package com.validei.api.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record ForgotPasswordRequest(
        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        String email
) {
    public ForgotPasswordRequest {
        email = email == null ? null : email.trim();
    }
}
