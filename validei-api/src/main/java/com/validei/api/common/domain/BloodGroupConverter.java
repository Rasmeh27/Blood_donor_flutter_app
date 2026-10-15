package com.validei.api.common.domain;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

// Guarda BloodGroup en MySQL como "A+", "O-", etc.
@Converter
public class BloodGroupConverter implements AttributeConverter<BloodGroup, String> {

    @Override
    public String convertToDatabaseColumn(BloodGroup bloodGroup) {
        return bloodGroup == null ? null : bloodGroup.getLabel();
    }

    @Override
    public BloodGroup convertToEntityAttribute(String label) {
        return label == null ? null : BloodGroup.fromLabel(label);
    }
}
