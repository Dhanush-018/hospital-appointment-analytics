{{ config(
    materialized='view',
    catalog='hospital_appointments',
    schema='silver',
    alias='stg_batch2_valid'
) }}

SELECT *
FROM {{ ref('int_batch2_classified') }}
WHERE record_class = 'VALID'