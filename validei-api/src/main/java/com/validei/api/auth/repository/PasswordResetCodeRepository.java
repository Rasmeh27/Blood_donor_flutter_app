package com.validei.api.auth.repository;

import com.validei.api.auth.entity.PasswordResetCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, Long> {

    // Solo el último código sin consumir puede ser válido (los anteriores se invalidan al crear uno nuevo)
    Optional<PasswordResetCode> findFirstByUserIdAndConsumedAtIsNullOrderByCreatedAtDescIdDesc(Long userId);

    @Modifying
    @Query("""
            update PasswordResetCode c
               set c.consumedAt = :now
             where c.user.id = :userId
               and c.consumedAt is null
            """)
    int invalidatePendingCodes(@Param("userId") Long userId, @Param("now") Instant now);
}
