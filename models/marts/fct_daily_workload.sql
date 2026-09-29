select
    dates.date_key,
    workload.workload_date,
    workload.tickets_opened,
    workload.tickets_resolved,
    workload.open_backlog

from {{ ref('int_daily_workload') }} as workload
inner join {{ ref('dim_date') }} as dates
    on workload.workload_date = dates.calendar_date
