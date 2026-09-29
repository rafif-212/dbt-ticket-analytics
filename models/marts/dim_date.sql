with calendar as (

    select * from {{ ref('stg_nz_calendar') }}

),

known_dates as (

    select
        cast({{ date_key('calendar_date') }} as integer)   as date_key,
        calendar_date,
        cast(extract(year from calendar_date) as integer)    as calendar_year,
        cast(extract(quarter from calendar_date) as integer) as calendar_quarter,
        cast(extract(month from calendar_date) as integer)   as calendar_month,
        monthname(calendar_date)                             as month_name,
        cast(extract(isodow from calendar_date) as integer)  as iso_day_of_week,
        dayname(calendar_date)                               as day_name,
        is_weekend,
        is_business_day,
        is_national_holiday,
        national_holiday_name,
        is_long_weekend_holiday

    from calendar

),

-- Special members so every fact row has a date to point at: -1 for dates
-- that fail the quality rules, -2 for tickets that are not resolved yet.
special_members as (

    select
        -1 as date_key, cast(null as date) as calendar_date,
        null as calendar_year, null as calendar_quarter, null as calendar_month,
        'Invalid date' as month_name, null as iso_day_of_week, 'Invalid date' as day_name,
        false as is_weekend, false as is_business_day, false as is_national_holiday,
        null as national_holiday_name, false as is_long_weekend_holiday

    union all

    select
        -2, cast(null as date),
        null, null, null,
        'Not resolved', null, 'Not resolved',
        false, false, false,
        null, false

)

select * from known_dates
union all
select * from special_members
