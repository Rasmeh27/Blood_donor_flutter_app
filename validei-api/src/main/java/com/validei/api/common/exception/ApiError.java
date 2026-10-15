package com.validei.api.common.exception;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ApiError(
        int status,
        String error,
        String message,
        String path,
        List<FieldViolation> fields
) {

    public record FieldViolation(String field, String message) { }
}
