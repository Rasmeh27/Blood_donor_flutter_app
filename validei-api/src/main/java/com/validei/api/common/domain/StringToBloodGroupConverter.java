package com.validei.api.common.domain;

import org.springframework.core.convert.converter.Converter;
import org.springframework.stereotype.Component;

// Permite recibir parámetros de URL como ?bloodGroup=A%2B (el "+" debe ir codificado)
@Component
public class StringToBloodGroupConverter implements Converter<String, BloodGroup> {

    @Override
    public BloodGroup convert(String label) {
        return BloodGroup.fromLabel(label.trim());
    }
}
