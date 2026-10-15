package com.validei.api.donor.dto;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.donor.entity.Donor;

import java.time.LocalDate;

public record DonorResponse(
        Long id,
        String name,
        String contactNumber,
        BloodGroup bloodGroup,
        String location,
        LocalDate lastDonationDate,
        boolean visibleInSearch,
        boolean hasPhoto
) {
    public static DonorResponse from(Donor donor) {
        return new DonorResponse(
                donor.getId(),
                donor.getFullName(),
                donor.getContactNumber(),
                donor.getBloodGroup(),
                donor.getLocation(),
                donor.getLastDonationDate(),
                donor.isVisibleInSearch(),
                donor.getPhotoFile() != null
        );
    }
}
