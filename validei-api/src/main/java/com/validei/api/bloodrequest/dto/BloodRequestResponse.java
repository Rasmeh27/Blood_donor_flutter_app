package com.validei.api.bloodrequest.dto;

import com.validei.api.bloodrequest.entity.BloodRequest;
import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.domain.Gender;
import com.validei.api.common.time.ServerTime;

import java.time.LocalDate;
import java.time.Instant;

// Se usa tanto en el feed/listado como en el detalle; createdAt (UTC) permite mostrar "2 minute ago"
public record BloodRequestResponse(
        Long id,
        BloodGroup bloodGroup,
        Integer bags,
        String contactNumber,
        String emergencyContact,
        String patientName,
        String caseDescription,
        Gender patientGender,
        LocalDate needBefore,
        String location,
        String others,
        Instant createdAt
) {
    public static BloodRequestResponse from(BloodRequest request) {
        return new BloodRequestResponse(
                request.getId(),
                request.getBloodGroup(),
                request.getBags(),
                request.getContactNumber(),
                request.getEmergencyContact(),
                request.getPatientName(),
                request.getCaseDescription(),
                request.getPatientGender(),
                request.getNeedBefore(),
                request.getLocation(),
                request.getOthers(),
                ServerTime.toInstant(request.getCreatedAt())
        );
    }
}
