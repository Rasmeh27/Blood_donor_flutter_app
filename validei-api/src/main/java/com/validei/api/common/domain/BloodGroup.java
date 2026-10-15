package com.validei.api.common.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Arrays;

/**
 * Los 8 grupos de CustomBloodGroupBox. En JSON y en MySQL se usa la etiqueta visible ("A+", "O-").
 */
public enum BloodGroup {
    A_POSITIVE("A+"),
    B_POSITIVE("B+"),
    AB_POSITIVE("AB+"),
    O_POSITIVE("O+"),
    A_NEGATIVE("A-"),
    B_NEGATIVE("B-"),
    AB_NEGATIVE("AB-"),
    O_NEGATIVE("O-");

    private final String label;

    BloodGroup(String label) {
        this.label = label;
    }

    @JsonValue
    public String getLabel() {
        return label;
    }

    @JsonCreator
    public static BloodGroup fromLabel(String label) {
        return Arrays.stream(values())
                .filter(group -> group.label.equalsIgnoreCase(label))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Grupo sanguíneo no válido: " + label));
    }
}
