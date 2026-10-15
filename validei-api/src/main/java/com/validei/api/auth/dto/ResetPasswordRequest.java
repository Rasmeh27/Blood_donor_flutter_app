package com.validei.api.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// La nueva contraseña sigue las mismas reglas que el registro (RegisterRequest)
public record ResetPasswordRequest(
        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        String email,

        @NotBlank(message = "El código es obligatorio")
        @Pattern(regexp = "\\d{6}", message = "El código debe tener 6 dígitos")
        String code,

        @NotBlank(message = "La contraseña es obligatoria")
        @Size(min = 8, max = 64, message = "la contraseña debes ser de 8 a 64 caracteres")
        @Pattern(
                regexp = ".*[#?!@$%^&*-].*",
                message = "La contraseña debe incluir al menos un carácter especial (#?!@$%^&*-)"
        )
        String newPassword
) {
    public ResetPasswordRequest {
        email = email == null ? null : email.trim();
    }
}
