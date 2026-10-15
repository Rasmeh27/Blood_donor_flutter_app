package com.validei.api;

import com.validei.api.common.time.ServerTime;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;

@SpringBootApplication
public class ValideiApiApplication {

	public static void main(String[] args) {
		// Zona en la que se escribieron los timestamps existentes (UTC-4, sin horario de verano).
		// Fijarla evita que los datos históricos cambien de significado si el servidor corre en otra zona.
		TimeZone.setDefault(TimeZone.getTimeZone(ServerTime.ZONE));
		SpringApplication.run(
				ValideiApiApplication.class,
				args
		);
	}
}