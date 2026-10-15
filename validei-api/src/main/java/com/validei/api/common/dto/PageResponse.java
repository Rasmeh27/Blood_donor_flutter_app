package com.validei.api.common.dto;

import org.springframework.data.domain.Page;

import java.util.List;

// Respuesta paginada estable para el cliente (evita serializar PageImpl de Spring Data)
public record PageResponse<T>(
        List<T> content,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static <T> PageResponse<T> from(Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages()
        );
    }
}
