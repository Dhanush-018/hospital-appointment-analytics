{{ config(materialized='ephemeral') }}

WITH raw_batch AS (
    SELECT *
    FROM hospital_appointments.bronze.all_raw_data
    WHERE batch_id = 'BATCH_02'
),

invalid_rows AS (
    SELECT
        *,
        CASE
            WHEN appointment_id IS NULL
                THEN 'Missing appointment_id'
            WHEN patient_id IS NULL
                THEN 'Missing patient_id'
            WHEN doctor_id IS NULL
                THEN 'Missing doctor_id'
            WHEN TRY_CAST(appointment_date AS DATE) IS NULL
                THEN 'Invalid appointment_date'
            WHEN TRY_CAST(consultation_fee AS DECIMAL(10,2)) IS NULL
                THEN 'Missing or invalid consultation_fee'
            WHEN TRY_CAST(consultation_fee AS DECIMAL(10,2)) < 0
                THEN 'Negative consultation_fee'
            WHEN TRY_CAST(test_charge AS DECIMAL(10,2)) IS NULL
                THEN 'Missing or invalid test_charge'
            WHEN TRY_CAST(test_charge AS DECIMAL(10,2)) < 0
                THEN 'Negative test_charge'
        END AS rejection_reason
    FROM raw_batch
),

valid_rows AS (
    SELECT *
    FROM invalid_rows
    WHERE rejection_reason IS NULL
),

ranked_valid_rows AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY appointment_id
            ORDER BY ingestion_timestamp DESC
        ) AS duplicate_rank
    FROM valid_rows
)

SELECT
    *,
    CASE
        WHEN rejection_reason IS NOT NULL THEN 'INVALID'
        WHEN duplicate_rank > 1 THEN 'DUPLICATE'
        ELSE 'VALID'
    END AS record_class
FROM (
    SELECT
        *,
        CAST(NULL AS INT) AS duplicate_rank
    FROM invalid_rows
    WHERE rejection_reason IS NOT NULL

    UNION ALL

    SELECT *
    FROM ranked_valid_rows
) classified