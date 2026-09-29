-- int_daily_workload rebuilds the original project's daily_workload table from
-- ticket rows. Every day must match on intake and backlog; a mismatch means
-- the flagged set or the backlog logic differs from the table the Power BI
-- report was built on.

select
    rebuilt.workload_date,
    rebuilt.tickets_opened,
    supplied.tickets_opened   as supplied_tickets_opened,
    rebuilt.open_backlog,
    supplied.open_backlog     as supplied_open_backlog

from {{ ref('int_daily_workload') }} as rebuilt
full outer join {{ ref('stg_daily_workload') }} as supplied
    on rebuilt.workload_date = supplied.workload_date

where rebuilt.workload_date is null
   or supplied.workload_date is null
   or rebuilt.tickets_opened <> supplied.tickets_opened
   or rebuilt.open_backlog <> supplied.open_backlog
