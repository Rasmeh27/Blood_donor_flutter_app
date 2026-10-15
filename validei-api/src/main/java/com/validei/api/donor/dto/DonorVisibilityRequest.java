package com.validei.api.donor.dto;

import jakarta.validation.constraints.NotNull;

public record DonorVisibilityRequest(
        @NotNull(message = "Indique si desea aparecer en la búsqueda de donantes")
        Boolean visibleInSearch
) { }
