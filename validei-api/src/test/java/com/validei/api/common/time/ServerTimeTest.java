package com.validei.api.common.time;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.TimeZone;

import static org.assertj.core.api.Assertions.assertThat;

class ServerTimeTest {

    @Test
    void convertsServerLocalTimestampToUtcInstant() {
        TimeZone original = TimeZone.getDefault();
        try {
            TimeZone.setDefault(TimeZone.getTimeZone(ServerTime.ZONE));

            Instant instant = ServerTime.toInstant(LocalDateTime.parse("2026-10-14T18:27:06.293918"));

            // Santo Domingo es UTC-4 todo el año: 18:27 local = 22:27 UTC
            assertThat(instant).isEqualTo(Instant.parse("2026-10-14T22:27:06.293918Z"));
        } finally {
            TimeZone.setDefault(original);
        }
    }

    @Test
    void serverZoneHasNoDaylightSavingTime() {
        ZoneId zone = ServerTime.ZONE;

        assertThat(zone.getRules().getOffset(Instant.parse("2026-01-15T12:00:00Z")))
                .isEqualTo(zone.getRules().getOffset(Instant.parse("2026-07-15T12:00:00Z")));
    }

    @Test
    void keepsNullValues() {
        assertThat(ServerTime.toInstant(null)).isNull();
    }
}
