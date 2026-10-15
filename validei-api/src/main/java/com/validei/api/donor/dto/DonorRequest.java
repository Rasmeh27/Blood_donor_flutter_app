package com.validei.api.donor.dto;

import com.validei.api.common.domain.BloodGroup;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

// Campos marcados como "*required" en DonorRegistrationForm
public record DonorRequest(

        @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 120, message = "El nombre no puede superar 120 caracteres")
        String name,

        @NotBlank(message = "El número de contacto es obligatorio")
        @Pattern(regexp = "^\\+?[0-9]{7,15}$", message = "El teléfono debe tener entre 7 y 15 dígitos")
        String contactNumber,

        @NotNull(message = "El grupo sanguíneo es obligatorio")
        BloodGroup bloodGroup,

        @NotBlank(message = "La ubicación es obligatoria")
        @Size(max = 150, message = "La ubicación no puede superar 150 caracteres")
        String location,

        @NotNull(message = "La fecha de la última donación es obligatoria")
        @PastOrPresent(message = "La fecha de la última donación no puede ser futura")
        LocalDate lastDonationDate
) { }
