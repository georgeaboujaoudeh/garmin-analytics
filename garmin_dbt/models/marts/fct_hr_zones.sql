{{ config(materialized='table') }}

with activities as (

    select
        activity_id,
        date(started_at)                       as activity_date,
        activity_type,
        duration_seconds,
        coalesce(hr_zone_1_seconds, 0)         as z1_sec,
        coalesce(hr_zone_2_seconds, 0)         as z2_sec,
        coalesce(hr_zone_3_seconds, 0)         as z3_sec,
        coalesce(hr_zone_4_seconds, 0)         as z4_sec,
        coalesce(hr_zone_5_seconds, 0)         as z5_sec
    from {{ ref('stg_activities') }}
    where coalesce(hr_zone_1_seconds, 0)
        + coalesce(hr_zone_2_seconds, 0)
        + coalesce(hr_zone_3_seconds, 0)
        + coalesce(hr_zone_4_seconds, 0)
        + coalesce(hr_zone_5_seconds, 0) > 0

),

with_totals as (

    select
        activity_id,
        activity_date,
        activity_type,
        duration_seconds,
        z1_sec, z2_sec, z3_sec, z4_sec, z5_sec,
        (z1_sec + z2_sec + z3_sec + z4_sec + z5_sec) as total_zone_sec,
        (z1_sec + z2_sec) as easy_sec,
        (z3_sec)          as moderate_sec,
        (z4_sec + z5_sec) as hard_sec
    from activities

),

scored as (

    select
        activity_id,
        activity_date,
        activity_type,
        round(duration_seconds / 60.0, 1)                       as duration_min,

        round(z1_sec / 60.0, 1)                                 as z1_min,
        round(z2_sec / 60.0, 1)                                 as z2_min,
        round(z3_sec / 60.0, 1)                                 as z3_min,
        round(z4_sec / 60.0, 1)                                 as z4_min,
        round(z5_sec / 60.0, 1)                                 as z5_min,

        round(100.0 * z1_sec / nullif(total_zone_sec, 0), 1)    as z1_pct,
        round(100.0 * z2_sec / nullif(total_zone_sec, 0), 1)    as z2_pct,
        round(100.0 * z3_sec / nullif(total_zone_sec, 0), 1)    as z3_pct,
        round(100.0 * z4_sec / nullif(total_zone_sec, 0), 1)    as z4_pct,
        round(100.0 * z5_sec / nullif(total_zone_sec, 0), 1)    as z5_pct,

        round(100.0 * easy_sec     / nullif(total_zone_sec, 0), 1) as easy_pct,
        round(100.0 * moderate_sec / nullif(total_zone_sec, 0), 1) as moderate_pct,
        round(100.0 * hard_sec     / nullif(total_zone_sec, 0), 1) as hard_pct,

        case
            when 100.0 * easy_sec / nullif(total_zone_sec, 0) >= 75 then 'polarized_easy'
            when 100.0 * hard_sec / nullif(total_zone_sec, 0) >= 40 then 'high_intensity'
            when 100.0 * moderate_sec / nullif(total_zone_sec, 0) >= 50 then 'gray_zone'
            else 'mixed'
        end as session_profile

    from with_totals

)

select * from scored
order by activity_date desc