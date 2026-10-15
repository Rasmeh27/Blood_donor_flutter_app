package com.validei.api.health;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("api/v1/health")
public class HealthController {

    @GetMapping
    public Map<String, String> getHealthStatus() {
        return Map.of(
                "Status: ", "UP",
                "message: ", "Aplicacion arriba"
        );
    }

}
