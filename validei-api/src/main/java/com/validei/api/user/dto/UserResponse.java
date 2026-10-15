package com.validei.api.user.dto;
import com.validei.api.common.domain.Gender;
import com.validei.api.user.entity.User;
import com.validei.api.common.time.ServerTime;

import java.time.Instant;

public record UserResponse(
        Long id,
        String name,
        String email,
        String phone,
        Gender gender,
        String location,
        Instant createdAt
) {
    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhone(),
                user.getGender(),
                user.getLocation(),
                ServerTime.toInstant(user.getCreatedAt())
        );
    }
}
