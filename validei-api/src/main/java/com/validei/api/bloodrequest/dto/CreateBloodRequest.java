package com.validei.api.bloodrequest.dto;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.domain.Gender;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

// Campos "*required" de FindDonorScreen; patientGender, location y others son opcionales
public record CreateBloodRequest(

        @NotNull(message = "El grupo sanguíneo es obligatorio")
        BloodGroup bloodGroup,

        @NotNull(message = "El número de bolsas es obligatorio")
        @Min(value = 1, message = "Debe solicitar al menos 1 bolsa")
        @Max(value = 10, message = "No puede solicitar más de 10 bolsas")
        Integer bags,

        @NotBlank(message = "El número de contacto es obligatorio")
        @Pattern(regexp = "^\\+?[0-9]{7,15}$", message = "El teléfono debe tener entre 7 y 15 dígitos")
        String contactNumber,

        @NotBlank(message = "El contacto de emergencia es obligatorio")
        @Pattern(regexp = "^\\+?[0-9]{7,15}$", message = "El teléfono debe tener entre 7 y 15 dígitos")
        String emergencyContact,

        @NotBlank(message = "El nombre del paciente es obligatorio")
        @Size(max = 120, message = "El nombre del paciente no puede superar 120 caracteres")
        String patientName,

        @NotBlank(message = "El caso es obligatorio")
        @Size(max = 150, message = "El caso no puede superar 150 caracteres")
        String caseDescription,

        Gender patientGender,

        @NotNull(message = "La fecha límite es obligatoria")
        @FutureOrPresent(message = "La fecha límite no puede estar en el pasado")
        LocalDate needBefore,

        @Size(max = 150, message = "La ubicación no puede superar 150 caracteres")
        String location,

        @Size(max = 255, message = "El campo otros no puede superar 255 caracteres")
        String others
) { }
