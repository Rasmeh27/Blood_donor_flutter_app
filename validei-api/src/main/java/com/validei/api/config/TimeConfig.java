package com.validei.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

import java.time.Clock;

@Configuration
@EnableAsync
public class TimeConfig {

    // Reloj inyectable: permite probar expiraciones y límites de frecuencia sin esperar
    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }
}
