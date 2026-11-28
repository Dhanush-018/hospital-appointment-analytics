{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='appointment_id',
    catalog='hospital_appointments',
    schema='silver',
    alias='silver_data'
) }}

SELECT
    appointment_id,
    patient_id,
    patient_name,
    patient_age,
    patient_gender,
    hospital_city,
    hospital_city AS city,
    doctor_id,
    doctor_name,
    department,
    appointment_date,
    consultation_fee,
    test_charge,
    COALESCE(consultation_fee, 0)
        + COALESCE(test_charge, 0) AS appointment_amount,
    appointment_status,
    source_file,
    batch_id,
    ingestion_timestamp
FROM {{ ref('stg_batch2_valid') }}