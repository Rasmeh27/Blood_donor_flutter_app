package com.validei.api.bloodrequest.entity;

import com.validei.api.bloodrequest.dto.CreateBloodRequest;
import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.domain.BloodGroupConverter;
import com.validei.api.common.domain.Gender;
import com.validei.api.user.entity.User;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "blood_requests")
public class BloodRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requester_id", nullable = false)
    private User requester;

    @Convert(converter = BloodGroupConverter.class)
    @Column(name = "blood_group", nullable = false, length = 3)
    private BloodGroup bloodGroup;

    @JdbcTypeCode(SqlTypes.TINYINT)
    @Column(nullable = false)
    private Integer bags;

    @Column(name = "contact_number", nullable = false, length = 20)
    private String contactNumber;

    @Column(name = "emergency_contact", nullable = false, length = 20)
    private String emergencyContact;

    @Column(name = "patient_name", nullable = false, length = 120)
    private String patientName;

    @Column(name = "case_description", nullable = false, length = 150)
    private String caseDescription;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "patient_gender", length = 10)
    private Gender patientGender;

    @Column(name = "need_before", nullable = false)
    private LocalDate needBefore;

    @Column(length = 150)
    private String location;

    @Column(length = 255)
    private String others;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected BloodRequest() {
    }

    // location ya resuelta por el servicio (la enviada o la del perfil del solicitante)
    public BloodRequest(User requester, CreateBloodRequest request, String location) {
        this.requester = requester;
        this.bloodGroup = request.bloodGroup();
        this.bags = request.bags();
        this.contactNumber = request.contactNumber().trim();
        this.emergencyContact = request.emergencyContact().trim();
        this.patientName = request.patientName().trim();
        this.caseDescription = request.caseDescription().trim();
        this.patientGender = request.patientGender();
        this.needBefore = request.needBefore();
        this.location = trimOrNull(location);
        this.others = trimOrNull(request.others());
    }

    private static String trimOrNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public Long getId() {
        return id;
    }

    public User getRequester() {
        return requester;
    }

    public BloodGroup getBloodGroup() {
        return bloodGroup;
    }

    public Integer getBags() {
        return bags;
    }

    public String getContactNumber() {
        return contactNumber;
    }

    public String getEmergencyContact() {
        return emergencyContact;
    }

    public String getPatientName() {
        return patientName;
    }

    public String getCaseDescription() {
        return caseDescription;
    }

    public Gender getPatientGender() {
        return patientGender;
    }

    public LocalDate getNeedBefore() {
        return needBefore;
    }

    public String getLocation() {
        return location;
    }

    public String getOthers() {
        return others;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
