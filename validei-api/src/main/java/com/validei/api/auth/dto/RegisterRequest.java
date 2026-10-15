package com.validei.api.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

        @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 120)
        String name,

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        @Size(max = 254)
        String email,

        // Mismas reglas que passwordValidator en el frontend (lib/src/constants/validators.dart)
        @NotBlank(message = "La contraseña es obligatoria")
        @Size(min = 8, max = 64, message = "la contraseña debes ser de 8 a 64 caracteres")
        @Pattern(
                regexp = ".*[#?!@$%^&*-].*",
                message = "La contraseña debe incluir al menos un carácter especial (#?!@$%^&*-)"
        )
        String password
) {
    // Se recortan los espacios antes de validar el formato del correo
    public RegisterRequest {
        email = email == null ? null : email.trim();
    }
}
