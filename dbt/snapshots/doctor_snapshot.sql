{% snapshot doctor_snapshot %}

{{
    config(
        target_database='hospital_appointments',
        target_schema='snapshots',
        unique_key='doctor_id',
        strategy='check',
        check_cols=['doctor_name', 'department']
    )
}}

SELECT
    doctor_id,
    doctor_name,
    department
FROM {{ source('gold', 'dim_doctor') }}

{% endsnapshot %}