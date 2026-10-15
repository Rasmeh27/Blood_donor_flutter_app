package com.validei.api.common.security;

import org.springframework.security.oauth2.jwt.Jwt;

public final class CurrentUser {

    private CurrentUser() {
    }

    // El claim "sub" contiene el id del usuario (ver JwtService)
    public static Long id(Jwt jwt) {
        return Long.valueOf(jwt.getSubject());
    }
}
