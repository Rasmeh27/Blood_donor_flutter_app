package com.validei.api.auth.dto;

import com.validei.api.user.dto.UserResponse;

import java.time.Instant;

public record AuthResponse(
        String tokenType,
        String accessToken,
        Instant expiresAt,
        UserResponse user
) { }
