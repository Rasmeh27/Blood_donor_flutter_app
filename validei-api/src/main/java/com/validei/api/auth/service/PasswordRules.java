package com.validei.api.auth.service;

import java.nio.charset.StandardCharsets;

final class PasswordRules {

    // BCrypt solo procesa los primeros 72 bytes de la contraseña
    private static final int BCRYPT_MAX_PASSWORD_BYTES = 72;

    private PasswordRules() {
    }

    static boolean exceedsBcryptLimit(String password) {
        return password.getBytes(StandardCharsets.UTF_8).length > BCRYPT_MAX_PASSWORD_BYTES;
    }
}
