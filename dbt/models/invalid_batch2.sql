{{ config(
    materialized='table',
    catalog='hospital_appointments',
    schema='bronze',
    alias='invalid_batch2'
) }}

SELECT *
FROM {{ ref('int_batch2_classified') }}
WHERE record_class = 'INVALID'