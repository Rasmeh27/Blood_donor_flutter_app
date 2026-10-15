package com.validei.api.auth.service;

import com.validei.api.common.exception.TooManyRequestsException;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PasswordResetRateLimiterTest {

    private Instant now = Instant.parse("2026-10-14T12:00:00Z");

    private final Clock clock = new Clock() {
        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    };

    private final PasswordResetRateLimiter limiter = new PasswordResetRateLimiter(clock, 60, 5);

    @Test
    void requiresOneMinuteBetweenRequests() {
        limiter.checkAndRecord("ana@mail.com");

        now = now.plusSeconds(30);
        assertThatThrownBy(() -> limiter.checkAndRecord("ana@mail.com"))
                .isInstanceOf(TooManyRequestsException.class);

        now = now.plusSeconds(31);
        assertThatCode(() -> limiter.checkAndRecord("ana@mail.com")).doesNotThrowAnyException();
    }

    @Test
    void allowsAtMostFiveRequestsPerHour() {
        for (int i = 0; i < 5; i++) {
            limiter.checkAndRecord("ana@mail.com");
            now = now.plus(Duration.ofMinutes(2));
        }

        assertThatThrownBy(() -> limiter.checkAndRecord("ana@mail.com"))
                .isInstanceOf(TooManyRequestsException.class);

        now = now.plus(Duration.ofMinutes(55));
        assertThatCode(() -> limiter.checkAndRecord("ana@mail.com")).doesNotThrowAnyException();
    }

    @Test
    void limitsEachEmailIndependently() {
        limiter.checkAndRecord("ana@mail.com");

        assertThatCode(() -> limiter.checkAndRecord("luis@mail.com")).doesNotThrowAnyException();
    }
}
