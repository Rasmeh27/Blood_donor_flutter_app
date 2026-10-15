package com.validei.api.common.time;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

/**
 * Las columnas created_at/updated_at (LocalDateTime) las escribe Hibernate con la hora local del servidor,
 * cuya zona se fija al arrancar (ver ValideiApiApplication). Para transmitirlas sin ambigüedad se
 * convierten a Instant (UTC, ISO 8601) usando esa misma zona; los datos guardados no se modifican.
 */
public final class ServerTime {

    public static final ZoneId ZONE = ZoneId.of("America/Santo_Domingo");

    private ServerTime() {
    }

    public static Instant toInstant(LocalDateTime serverLocalTime) {
        return serverLocalTime == null ? null : serverLocalTime.atZone(ZoneId.systemDefault()).toInstant();
    }
}
