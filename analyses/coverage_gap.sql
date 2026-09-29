-- Monthly intake and resolutions from the rebuilt daily workload. Shows the
-- 2025 gap: intake stops after December 2024 apart from one day in March,
-- while resolutions of older tickets carry on.

select
    dates.calendar_year,
    dates.calendar_month,
    sum(workload.tickets_opened)                              as tickets_opened,
    sum(workload.tickets_resolved)                            as tickets_resolved,
    count(*) filter (where workload.tickets_opened = 0)       as days_with_no_intake

from {{ ref('fct_daily_workload') }} as workload
inner join {{ ref('dim_date') }} as dates
    on workload.date_key = dates.date_key

group by 1, 2
order by 1, 2
