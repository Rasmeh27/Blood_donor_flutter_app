package com.validei.api.auth.entity;

import com.validei.api.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "password_reset_codes")
public class PasswordResetCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "code_hash", nullable = false, length = 100)
    private String codeHash;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts;

    // Fecha en que el código se usó, se agotaron sus intentos o fue reemplazado por uno nuevo
    @Column(name = "consumed_at")
    private Instant consumedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected PasswordResetCode() {
    }

    public PasswordResetCode(User user, String codeHash, Instant createdAt, Instant expiresAt) {
        this.user = user;
        this.codeHash = codeHash;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
    }

    public boolean isUsable(Instant now) {
        return consumedAt == null && now.isBefore(expiresAt);
    }

    /** Suma un intento fallido; al llegar al máximo el código deja de servir. */
    public void registerFailedAttempt(int maxAttempts, Instant now) {
        failedAttempts++;
        if (failedAttempts >= maxAttempts) {
            consumedAt = now;
        }
    }

    public void consume(Instant now) {
        consumedAt = now;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public String getCodeHash() {
        return codeHash;
    }

    public int getFailedAttempts() {
        return failedAttempts;
    }

    public Instant getConsumedAt() {
        return consumedAt;
    }
}
