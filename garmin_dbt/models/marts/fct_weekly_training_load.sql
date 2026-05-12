{{ config(materialized='table') }}

with base as (

    select
        date_day,
        coalesce(total_calories_burned, 0) / 100.0 as daily_load,
        coalesce(total_duration_min, 0) as duration_min,
        coalesce(total_distance_km, 0)  as distance_km,
        had_workout
    from {{ ref('fct_daily_training') }}

),

with_windows as (

    select
        date_day,
        daily_load,
        duration_min,
        distance_km,
        had_workout,

        -- Acute load: 7-day rolling average
        avg(daily_load) over (
            order by date_day
            rows between 6 preceding and current row
        ) as acute_load_7d,

        -- Chronic load: 28-day rolling average
        avg(daily_load) over (
            order by date_day
            rows between 27 preceding and current row
        ) as chronic_load_28d,

        -- Weekly distance: rolling 7-day sum
        sum(distance_km) over (
            order by date_day
            rows between 6 preceding and current row
        ) as distance_km_7d,

        -- Weekly duration
        sum(duration_min) over (
            order by date_day
            rows between 6 preceding and current row
        ) as duration_min_7d

    from base

),

scored as (

    select
        date_day,
        daily_load,
        round(acute_load_7d::numeric, 2)        as acute_load_7d,
        round(chronic_load_28d::numeric, 2)     as chronic_load_28d,
        round(distance_km_7d::numeric, 1)       as distance_km_7d,
        round(duration_min_7d::numeric, 1)      as duration_min_7d,

        case
            when chronic_load_28d = 0 then null
            else round((acute_load_7d / chronic_load_28d)::numeric, 2)
        end as acwr,

        case
            when chronic_load_28d = 0 then 'insufficient_data'
            when acute_load_7d / chronic_load_28d < 0.8 then 'undertraining'
            when acute_load_7d / chronic_load_28d <= 1.3 then 'sweet_spot'
            when acute_load_7d / chronic_load_28d <= 1.5 then 'elevated'
            else 'injury_risk'
        end as load_status

    from with_windows

)

select * from scored
order by date_day desc