package com.validei.api.user.dto;

import com.validei.api.common.domain.Gender;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Actualización parcial del perfil: los campos ausentes (null) no se modifican.
 * El correo y la contraseña no se cambian por esta vía.
 */
public record UpdateProfileRequest(

        @Size(max = 120, message = "El nombre no puede superar 120 caracteres")
        @Pattern(regexp = ".*\\S.*", message = "El nombre no puede estar vacío")
        String name,

        @Pattern(regexp = "^\\+?[0-9]{7,15}$", message = "El teléfono debe tener entre 7 y 15 dígitos")
        String phone,

        Gender gender,

        @Size(max = 150, message = "La ubicación no puede superar 150 caracteres")
        @Pattern(regexp = ".*\\S.*", message = "La ubicación no puede estar vacía")
        String location
) { }
