package com.validei.api.donor.entity;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.domain.BloodGroupConverter;
import com.validei.api.user.entity.User;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "donors")
public class Donor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "full_name", nullable = false, length = 120)
    private String fullName;

    @Column(name = "contact_number", nullable = false, length = 20)
    private String contactNumber;

    @Convert(converter = BloodGroupConverter.class)
    @Column(name = "blood_group", nullable = false, length = 3)
    private BloodGroup bloodGroup;

    @Column(nullable = false, length = 150)
    private String location;

    @Column(name = "last_donation_date", nullable = false)
    private LocalDate lastDonationDate;

    // Consentimiento para aparecer en GET /api/v1/donors (por defecto no)
    @Column(name = "visible_in_search", nullable = false)
    private boolean visibleInSearch;

    // Nombre del archivo en disco (generado por el servidor), null si no tiene foto
    @Column(name = "photo_file", length = 100)
    private String photoFile;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected Donor() {
    }

    public Donor(User user) {
        this.user = user;
    }

    public void updateDetails(
            String fullName,
            String contactNumber,
            BloodGroup bloodGroup,
            String location,
            LocalDate lastDonationDate
    ) {
        this.fullName = fullName.trim();
        this.contactNumber = contactNumber.trim();
        this.bloodGroup = bloodGroup;
        this.location = location.trim();
        this.lastDonationDate = lastDonationDate;
    }

    public void updateSearchVisibility(boolean visibleInSearch) {
        this.visibleInSearch = visibleInSearch;
    }

    public void updatePhotoFile(String photoFile) {
        this.photoFile = photoFile;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public String getFullName() {
        return fullName;
    }

    public String getContactNumber() {
        return contactNumber;
    }

    public BloodGroup getBloodGroup() {
        return bloodGroup;
    }

    public String getLocation() {
        return location;
    }

    public LocalDate getLastDonationDate() {
        return lastDonationDate;
    }

    public boolean isVisibleInSearch() {
        return visibleInSearch;
    }

    public String getPhotoFile() {
        return photoFile;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
