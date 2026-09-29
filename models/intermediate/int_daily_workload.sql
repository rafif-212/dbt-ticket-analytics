with calendar as (

    select calendar_date from {{ ref('stg_nz_calendar') }}

),

-- Flagged tickets are left out because their dates are the thing in doubt.
-- This matches how the original project built daily_workload.
valid_tickets as (

    select created_date, resolved_date
    from {{ ref('int_tickets_enriched') }}
    where not has_data_quality_issue

),

opened as (

    select created_date as activity_date, count(*) as tickets_opened
    from valid_tickets
    group by 1

),

resolved as (

    select resolved_date as activity_date, count(*) as tickets_resolved
    from valid_tickets
    where resolved_date is not null
    group by 1

),

-- Starting from the calendar keeps days with no tickets as real zeros, so the
-- 2025 coverage gap shows up instead of being skipped.
daily as (

    select
        calendar.calendar_date                   as workload_date,
        coalesce(opened.tickets_opened, 0)       as tickets_opened,
        coalesce(resolved.tickets_resolved, 0)   as tickets_resolved

    from calendar
    left join opened
        on calendar.calendar_date = opened.activity_date
    left join resolved
        on calendar.calendar_date = resolved.activity_date

)

select
    workload_date,
    tickets_opened,
    tickets_resolved,
    -- Valid tickets are never resolved before they are created, so a running
    -- total of opened minus resolved equals tickets still open at day end.
    sum(tickets_opened - tickets_resolved) over (
        order by workload_date
        rows between unbounded preceding and current row
    ) as open_backlog

from daily
