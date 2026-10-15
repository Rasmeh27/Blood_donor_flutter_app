package com.validei.api.common.domain;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BloodGroupTest {

    private final BloodGroupConverter converter = new BloodGroupConverter();

    @Test
    void convertsBetweenLabelAndEnum() {
        assertThat(BloodGroup.fromLabel("AB-")).isEqualTo(BloodGroup.AB_NEGATIVE);
        assertThat(BloodGroup.fromLabel("o+")).isEqualTo(BloodGroup.O_POSITIVE);
        assertThat(converter.convertToDatabaseColumn(BloodGroup.A_POSITIVE)).isEqualTo("A+");
        assertThat(converter.convertToEntityAttribute("B-")).isEqualTo(BloodGroup.B_NEGATIVE);
    }

    @Test
    void containsTheEightGroupsOfTheFrontend() {
        assertThat(BloodGroup.values())
                .extracting(BloodGroup::getLabel)
                .containsExactly("A+", "B+", "AB+", "O+", "A-", "B-", "AB-", "O-");
    }

    @Test
    void rejectsUnknownLabel() {
        assertThatThrownBy(() -> BloodGroup.fromLabel("C+"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
