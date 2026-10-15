package com.validei.api.auth.service;

import com.validei.api.common.exception.TooManyRequestsException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;

/**
 * Limita las solicitudes de código por correo: una cada minuto y un máximo por hora.
 * Se aplica igual a correos registrados y no registrados para no revelar cuáles existen.
 * Memoria local: suficiente para una sola instancia del backend (alcance académico).
 */
@Component
public class PasswordResetRateLimiter {

    private static final Duration WINDOW = Duration.ofHours(1);

    private final Clock clock;
    private final Duration cooldown;
    private final int maxRequestsPerHour;
    private final Map<String, Deque<Instant>> requestsByEmail = new HashMap<>();

    public PasswordResetRateLimiter(
            Clock clock,
            @Value("${app.password-reset.request-cooldown-seconds}") long cooldownSeconds,
            @Value("${app.password-reset.max-requests-per-hour}") int maxRequestsPerHour
    ) {
        this.clock = clock;
        this.cooldown = Duration.ofSeconds(cooldownSeconds);
        this.maxRequestsPerHour = maxRequestsPerHour;
    }

    public synchronized void checkAndRecord(String normalizedEmail) {
        Instant now = clock.instant();
        Deque<Instant> requests = requestsByEmail.computeIfAbsent(normalizedEmail, key -> new ArrayDeque<>());
        requests.removeIf(requestedAt -> requestedAt.isBefore(now.minus(WINDOW)));

        boolean tooSoon = !requests.isEmpty() && requests.peekLast().isAfter(now.minus(cooldown));
        if (tooSoon || requests.size() >= maxRequestsPerHour) {
            throw new TooManyRequestsException("Espera antes de solicitar otro código");
        }

        requests.addLast(now);
    }
}
