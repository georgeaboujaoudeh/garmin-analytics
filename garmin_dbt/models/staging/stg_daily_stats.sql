{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw', 'daily_stats') }}

),

renamed as (

    select
        stat_date,
        (payload ->> 'totalSteps')::numeric                         as steps,
        (payload ->> 'totalDistanceMeters')::numeric / 1000.0       as distance_km,
        (payload ->> 'totalKilocalories')::numeric                  as calories_total,
        (payload ->> 'activeKilocalories')::numeric                 as calories_active,
        (payload ->> 'minHeartRate')::numeric                       as hr_min,
        (payload ->> 'maxHeartRate')::numeric                       as hr_max,
        (payload ->> 'restingHeartRate')::numeric                   as hr_resting,
        (payload ->> 'averageStressLevel')::numeric                 as stress_avg,
        (payload ->> 'maxStressLevel')::numeric                     as stress_max,
        (payload ->> 'bodyBatteryChargedValue')::numeric            as body_battery_charged,
        (payload ->> 'bodyBatteryDrainedValue')::numeric            as body_battery_drained,
        (payload ->> 'highlyActiveSeconds')::numeric                as highly_active_seconds,
        (payload ->> 'activeSeconds')::numeric                      as active_seconds,
        (payload ->> 'sedentarySeconds')::numeric                   as sedentary_seconds,
        (payload ->> 'sleepingSeconds')::numeric                    as sleeping_seconds,
        loaded_at

    from source

)

select * from renamed