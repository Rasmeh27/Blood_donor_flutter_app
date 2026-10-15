package com.validei.api.donor.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import java.util.UUID;

/**
 * Guarda las fotos en un directorio local. El nombre de archivo lo genera el servidor (UUID),
 * nunca el cliente, para evitar rutas manipuladas.
 */
@Component
public class DonorPhotoStorage {

    private final Path directory;

    public DonorPhotoStorage(@Value("${app.storage.donor-photos-dir}") String directory) {
        this.directory = Path.of(directory).toAbsolutePath().normalize();
    }

    public String save(byte[] content, String extension) {
        String fileName = UUID.randomUUID() + "." + extension;
        try {
            Files.createDirectories(directory);
            Files.write(resolve(fileName), content);
            return fileName;
        } catch (IOException ex) {
            throw new UncheckedIOException("No se pudo guardar la foto", ex);
        }
    }

    public Optional<byte[]> load(String fileName) {
        Path file = resolve(fileName);
        if (!Files.isRegularFile(file)) {
            return Optional.empty();
        }
        try {
            return Optional.of(Files.readAllBytes(file));
        } catch (IOException ex) {
            throw new UncheckedIOException("No se pudo leer la foto", ex);
        }
    }

    public void delete(String fileName) {
        try {
            Files.deleteIfExists(resolve(fileName));
        } catch (IOException ex) {
            throw new UncheckedIOException("No se pudo eliminar la foto", ex);
        }
    }

    private Path resolve(String fileName) {
        Path file = directory.resolve(fileName).normalize();
        if (!file.startsWith(directory)) {
            throw new IllegalArgumentException("Nombre de archivo no válido");
        }
        return file;
    }
}
