package com.validei.api.donor.service;

import com.validei.api.common.exception.InvalidPhotoException;
import com.validei.api.common.exception.ResourceNotFoundException;
import com.validei.api.donor.dto.DonorResponse;
import com.validei.api.donor.entity.Donor;
import com.validei.api.donor.repository.DonorRepository;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;

@Service
public class DonorPhotoService {

    static final long MAX_PHOTO_BYTES = 2 * 1024 * 1024;

    private static final byte[] JPEG_SIGNATURE = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
    private static final byte[] PNG_SIGNATURE = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n'};

    private final DonorRepository donorRepository;
    private final DonorPhotoStorage storage;

    public DonorPhotoService(DonorRepository donorRepository, DonorPhotoStorage storage) {
        this.donorRepository = donorRepository;
        this.storage = storage;
    }

    /** Reemplaza la foto del donante. El formato se valida por su contenido, no por el nombre ni la cabecera. */
    @Transactional
    public DonorResponse replacePhoto(Long userId, MultipartFile photo) {
        Donor donor = findDonor(userId);
        byte[] content = readValidImage(photo);

        String previousFile = donor.getPhotoFile();
        donor.updatePhotoFile(storage.save(content, extensionOf(content)));
        Donor savedDonor = donorRepository.saveAndFlush(donor);

        if (previousFile != null) {
            storage.delete(previousFile);
        }
        return DonorResponse.from(savedDonor);
    }

    @Transactional(readOnly = true)
    public Photo getPhoto(Long userId) {
        Donor donor = findDonor(userId);
        String fileName = donor.getPhotoFile();
        if (fileName == null) {
            throw new ResourceNotFoundException("El donante no tiene foto");
        }

        byte[] content = storage.load(fileName)
                .orElseThrow(() -> new ResourceNotFoundException("El donante no tiene foto"));
        return new Photo(content, mediaTypeOf(content));
    }

    private Donor findDonor(Long userId) {
        return donorRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("El usuario no está registrado como donante"));
    }

    private byte[] readValidImage(MultipartFile photo) {
        if (photo.isEmpty()) {
            throw new InvalidPhotoException("Debe adjuntar una imagen");
        }
        if (photo.getSize() > MAX_PHOTO_BYTES) {
            throw new InvalidPhotoException("La imagen no puede superar 2 MB");
        }
        byte[] content;
        try {
            content = photo.getBytes();
        } catch (IOException ex) {
            throw new UncheckedIOException("No se pudo leer la imagen", ex);
        }
        if (!startsWith(content, JPEG_SIGNATURE) && !startsWith(content, PNG_SIGNATURE)) {
            throw new InvalidPhotoException("La imagen debe ser JPG o PNG");
        }
        return content;
    }

    private String extensionOf(byte[] content) {
        return startsWith(content, PNG_SIGNATURE) ? "png" : "jpg";
    }

    private MediaType mediaTypeOf(byte[] content) {
        return startsWith(content, PNG_SIGNATURE) ? MediaType.IMAGE_PNG : MediaType.IMAGE_JPEG;
    }

    private boolean startsWith(byte[] content, byte[] signature) {
        if (content.length < signature.length) {
            return false;
        }
        for (int i = 0; i < signature.length; i++) {
            if (content[i] != signature[i]) {
                return false;
            }
        }
        return true;
    }

    public record Photo(byte[] content, MediaType mediaType) {}
}
