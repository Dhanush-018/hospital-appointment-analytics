
{{ config(materialized='view') }}

WITH batch2 AS (
    SELECT *
    FROM {{ source('bronze', 'all_raw_data') }}
    WHERE batch_id = 'BATCH_02'
),

cleaned AS (
    SELECT
        TRIM(appointment_id) AS appointment_id,
        TRIM(patient_id) AS patient_id,
        INITCAP(TRIM(patient_name)) AS patient_name,
        patient_age,
        LOWER(TRIM(patient_gender)) AS patient_gender,

        -- Standardize city names
        INITCAP(TRIM(hospital_city)) AS hospital_city,

        TRIM(doctor_id) AS doctor_id,
        INITCAP(TRIM(doctor_name)) AS doctor_name,

        -- Standardize department names and preserve ENT
        CASE
            WHEN UPPER(TRIM(department)) = 'ENT' THEN 'ENT'
            ELSE INITCAP(TRIM(department))
        END AS department,

        appointment_date,
        CAST(consultation_fee AS DOUBLE) AS consultation_fee,
        CAST(test_charge AS DOUBLE) AS test_charge,

        CAST(consultation_fee AS DOUBLE)
            + CAST(test_charge AS DOUBLE) AS appointment_amount,

        INITCAP(TRIM(appointment_status)) AS appointment_status,
        source_file,
        batch_id,
        ingestion_timestamp

    FROM batch2
)

SELECT *
FROM cleaned
WHERE
    appointment_id IS NOT NULL
    AND appointment_id <> ''
    AND patient_id IS NOT NULL
    AND patient_id <> ''
    AND patient_name IS NOT NULL
    AND patient_name <> ''
    AND patient_age BETWEEN 1 AND 120
    AND LOWER(TRIM(patient_gender)) IN ('m', 'f')
    AND hospital_city IS NOT NULL
    AND TRIM(hospital_city) <> ''
    AND doctor_id IS NOT NULL
    AND doctor_id <> ''
    AND doctor_name IS NOT NULL
    AND TRIM(doctor_name) <> ''
    AND department IS NOT NULL
    AND TRIM(department) <> ''
    AND appointment_date IS NOT NULL
    AND CAST(consultation_fee AS DOUBLE) > 0
    AND CAST(test_charge AS DOUBLE) >= 0
    AND LOWER(TRIM(appointment_status))
        IN ('completed', 'scheduled', 'cancelled')
