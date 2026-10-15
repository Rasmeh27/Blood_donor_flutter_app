package com.validei.api.donor.dto;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.donor.entity.Donor;

import java.time.LocalDate;

// Datos públicos de la búsqueda: sin teléfono, correo ni identificador de usuario
public record DonorSearchResult(
        Long id,
        String name,
        BloodGroup bloodGroup,
        String location,
        LocalDate lastDonationDate
) {
    public static DonorSearchResult from(Donor donor) {
        return new DonorSearchResult(
                donor.getId(),
                donor.getFullName(),
                donor.getBloodGroup(),
                donor.getLocation(),
                donor.getLastDonationDate()
        );
    }
}
