-- The date dimension must have one row for every day between its first and
-- last date. A missing day would make a no-ticket day disappear from charts
-- instead of showing as zero, which is how the 2025 coverage gap would hide.

with known_dates as (

    select calendar_date
    from {{ ref('dim_date') }}
    where date_key > 0

),

summary as (

    select
        min(calendar_date)             as first_date,
        max(calendar_date)             as last_date,
        count(*)                       as day_rows,
        count(distinct calendar_date)  as distinct_days
    from known_dates

)

select *
from summary
where day_rows <> date_diff('day', first_date, last_date) + 1
   or distinct_days <> day_rows
