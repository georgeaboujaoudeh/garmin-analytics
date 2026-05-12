{{
    config(
        materialized='incremental',
        unique_key='activity_id',
        on_schema_change='append_new_columns'
    )
}}

with source as (

    select * from {{ source('raw', 'activities') }}

    {% if is_incremental() %}
        -- Only process rows loaded since the last successful run
        where loaded_at > (select coalesce(max(loaded_at), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}

),

renamed as (

    select
        activity_id,
        (payload ->> 'activityName')::text                          as activity_name,
        (payload -> 'activityType' ->> 'typeKey')::text             as activity_type,
        (payload ->> 'startTimeLocal')::timestamp                   as started_at,
        (payload ->> 'duration')::numeric                           as duration_seconds,
        (payload ->> 'distance')::numeric / 1000.0                  as distance_km,
        (payload ->> 'averageHR')::numeric                          as avg_hr,
        (payload ->> 'maxHR')::numeric                              as max_hr,
        (payload ->> 'averageSpeed')::numeric                       as avg_speed_ms,
        (payload ->> 'calories')::numeric                           as calories,
        (payload ->> 'elevationGain')::numeric                      as elevation_gain_m,
        (payload ->> 'aerobicTrainingEffect')::numeric              as aerobic_te,
        (payload ->> 'anaerobicTrainingEffect')::numeric            as anaerobic_te,
        (payload ->> 'trainingStressScore')::numeric                as training_stress_score,
        (payload ->> 'hrTimeInZone_1')::numeric                     as hr_zone_1_seconds,
        (payload ->> 'hrTimeInZone_2')::numeric                     as hr_zone_2_seconds,
        (payload ->> 'hrTimeInZone_3')::numeric                     as hr_zone_3_seconds,
        (payload ->> 'hrTimeInZone_4')::numeric                     as hr_zone_4_seconds,
        (payload ->> 'hrTimeInZone_5')::numeric                     as hr_zone_5_seconds,
        loaded_at

    from source

)

select * from renamed