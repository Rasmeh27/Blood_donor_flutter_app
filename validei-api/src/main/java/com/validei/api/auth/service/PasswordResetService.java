package com.validei.api.auth.service;

import com.validei.api.auth.entity.PasswordResetCode;
import com.validei.api.auth.repository.PasswordResetCodeRepository;
import com.validei.api.common.exception.InvalidResetCodeException;
import com.validei.api.user.entity.User;
import com.validei.api.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;

/**
 * Recuperación de contraseña en tres pasos: solicitar código, verificarlo y fijar la nueva contraseña.
 * Las respuestas no revelan si un correo está registrado.
 */
@Service
public class PasswordResetService {

    private static final int CODE_DIGITS = 6;
    private static final int CODE_BOUND = 1_000_000;

    private final UserRepository userRepository;
    private final PasswordResetCodeRepository codeRepository;
    private final PasswordEncoder passwordEncoder;
    private final PasswordResetMailer mailer;
    private final PasswordResetRateLimiter rateLimiter;
    private final Clock clock;
    private final Duration codeTtl;
    private final int maxAttempts;
    private final SecureRandom secureRandom = new SecureRandom();
    // Hash de referencia: si el correo no existe se compara igual, para no responder más rápido
    private final String referenceHash;

    public PasswordResetService(
            UserRepository userRepository,
            PasswordResetCodeRepository codeRepository,
            PasswordEncoder passwordEncoder,
            PasswordResetMailer mailer,
            PasswordResetRateLimiter rateLimiter,
            Clock clock,
            @Value("${app.password-reset.code-ttl-minutes}") long codeTtlMinutes,
            @Value("${app.password-reset.max-attempts}") int maxAttempts
    ) {
        this.userRepository = userRepository;
        this.codeRepository = codeRepository;
        this.passwordEncoder = passwordEncoder;
        this.mailer = mailer;
        this.rateLimiter = rateLimiter;
        this.clock = clock;
        this.codeTtl = Duration.ofMinutes(codeTtlMinutes);
        this.maxAttempts = maxAttempts;
        this.referenceHash = passwordEncoder.encode("000000");
    }

    @Transactional
    public void requestCode(String email) {
        String normalizedEmail = normalize(email);
        rateLimiter.checkAndRecord(normalizedEmail);

        userRepository.findByEmailIgnoreCase(normalizedEmail).ifPresent(user -> {
            Instant now = clock.instant();
            codeRepository.invalidatePendingCodes(user.getId(), now);

            String code = generateCode();
            codeRepository.save(new PasswordResetCode(
                    user,
                    passwordEncoder.encode(code),
                    now,
                    now.plus(codeTtl)
            ));
            mailer.sendCode(user.getEmail(), code);
        });
    }

    // noRollbackFor: el intento fallido debe quedar registrado aunque se responda con error
    @Transactional(noRollbackFor = InvalidResetCodeException.class)
    public void verifyCode(String email, String code) {
        findValidCode(email, code);
    }

    @Transactional(noRollbackFor = InvalidResetCodeException.class)
    public void resetPassword(String email, String code, String newPassword) {
        if (PasswordRules.exceedsBcryptLimit(newPassword)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "la contraseña es demasiado larga");
        }

        PasswordResetCode resetCode = findValidCode(email, code);
        User user = resetCode.getUser();

        user.updatePasswordHash(passwordEncoder.encode(newPassword));
        resetCode.consume(clock.instant());
    }

    private PasswordResetCode findValidCode(String email, String code) {
        Instant now = clock.instant();
        Optional<PasswordResetCode> pendingCode = userRepository.findByEmailIgnoreCase(normalize(email))
                .flatMap(user -> codeRepository
                        .findFirstByUserIdAndConsumedAtIsNullOrderByCreatedAtDescIdDesc(user.getId()))
                .filter(resetCode -> resetCode.isUsable(now));

        if (pendingCode.isEmpty()) {
            passwordEncoder.matches(code, referenceHash);
            throw new InvalidResetCodeException();
        }

        PasswordResetCode resetCode = pendingCode.get();
        if (!passwordEncoder.matches(code, resetCode.getCodeHash())) {
            resetCode.registerFailedAttempt(maxAttempts, now);
            throw new InvalidResetCodeException();
        }

        return resetCode;
    }

    private String generateCode() {
        return String.format("%0" + CODE_DIGITS + "d", secureRandom.nextInt(CODE_BOUND));
    }

    private String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
