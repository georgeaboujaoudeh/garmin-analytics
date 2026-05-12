{{ config(materialized='table') }}

with activities_daily as (

    select
        date(started_at)                          as activity_date,
        count(*)                                  as activity_count,
        sum(duration_seconds) / 60.0              as total_duration_min,
        sum(distance_km)                          as total_distance_km,
        sum(calories)                             as total_calories_burned,
        sum(elevation_gain_m)                     as total_elevation_gain_m,
        avg(avg_hr)                               as avg_activity_hr,
        max(max_hr)                               as max_activity_hr,
        sum(aerobic_te)                           as total_aerobic_te,
        sum(anaerobic_te)                         as total_anaerobic_te,
        string_agg(distinct activity_type, ', ')  as activity_types

    from {{ ref('stg_activities') }}
    group by 1

),

daily as (

    select
        stat_date,
        steps,
        distance_km                               as daily_distance_km,
        calories_total,
        calories_active,
        hr_resting,
        hr_max                                    as hr_max_day,
        stress_avg,
        body_battery_charged,
        body_battery_drained,
        highly_active_seconds / 60.0              as highly_active_min,
        active_seconds / 60.0                     as active_min,
        sedentary_seconds / 60.0                  as sedentary_min

    from {{ ref('stg_daily_stats') }}

),

joined as (

    select
        coalesce(d.stat_date, a.activity_date)    as date_day,

        -- activity-derived
        coalesce(a.activity_count, 0)             as activity_count,
        a.total_duration_min,
        a.total_distance_km,
        a.total_calories_burned,
        a.total_elevation_gain_m,
        a.avg_activity_hr,
        a.max_activity_hr,
        a.total_aerobic_te,
        a.total_anaerobic_te,
        a.activity_types,

        -- daily summary
        d.steps,
        d.daily_distance_km,
        d.calories_total,
        d.calories_active,
        d.hr_resting,
        d.hr_max_day,
        d.stress_avg,
        d.body_battery_charged,
        d.body_battery_drained,
        d.highly_active_min,
        d.active_min,
        d.sedentary_min,

        -- derived flags
        case when a.activity_count > 0 then true else false end as had_workout,
	case
            when a.total_calories_burned >= 700 then 'high'
            when a.total_calories_burned >= 400 then 'moderate'
            when a.total_calories_burned > 0    then 'low'
            else 'rest'
        end as training_intensity

    from daily d
    full outer join activities_daily a
        on d.stat_date = a.activity_date

)

select * from joined
order by date_day desc