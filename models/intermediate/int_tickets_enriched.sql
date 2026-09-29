with tickets as (

    select * from {{ ref('stg_tickets') }}

),

calendar_range as (

    select
        min(calendar_date) as first_calendar_date,
        max(calendar_date) as last_calendar_date
    from {{ ref('stg_nz_calendar') }}

),

holidays as (

    select * from {{ ref('stg_nz_holiday_days') }}

),

priority_targets as (

    select * from {{ ref('priority_sla_targets') }}

),

joined as (

    select
        tickets.*,
        calendar_range.first_calendar_date,
        calendar_range.last_calendar_date,
        priority_targets.standard_sla_target_hours,
        holidays.holiday_name   as created_holiday_name,
        holidays.holiday_scope  as created_holiday_scope,
        {{ dbt.datediff('tickets.created_date', 'tickets.resolved_date', 'day') }} as resolution_days

    from tickets
    cross join calendar_range
    left join priority_targets
        on tickets.priority = priority_targets.priority
    left join holidays
        on  tickets.region = holidays.region
        and tickets.created_date = holidays.holiday_date

),

quality_rules as (

    -- The first three rules reproduce the original data_quality_flag. The
    -- original bounded created dates with fixed dates (2023-07-01 and
    -- 2026-07-15); here the bound is the calendar the date dimension is built
    -- from, so any date that couldn't join to it is flagged.
    select
        *,
        coalesce(resolved_date < created_date, false)          as is_resolved_before_created,
        created_date not between first_calendar_date
                              and last_calendar_date           as is_created_outside_calendar,
        coalesce(created_date < account_created_date, false)   as is_created_before_account,
        coalesce(resolved_date not between first_calendar_date
                                   and last_calendar_date, false) as is_resolved_outside_calendar

    from joined

),

elapsed_bounds as (

    -- Dates carry no time of day, so a ticket resolved d days after creation
    -- took somewhere between 24(d-1) and 24(d+1) hours. SLA outcomes and the
    -- reconciliation of the supplied hours both work from these bounds.
    select
        *,
        is_resolved_before_created
            or is_created_outside_calendar
            or is_created_before_account
            or is_resolved_outside_calendar                    as has_data_quality_issue,
        greatest(0, 24 * (resolution_days - 1))                 as min_resolution_hours,
        24 * (resolution_days + 1)                              as max_resolution_hours

    from quality_rules

),

final as (

    select
        ticket_id,
        customer_account_id,
        created_date,
        resolved_date,
        resolved_date is not null                               as is_resolved,

        category,
        category_raw,
        priority,
        status,
        channel,
        service_area,
        region,
        customer_segment,
        subscription_type,
        assignee_team,
        assignee_name,
        is_escalated,
        csat_score,
        issue_complexity_score,

        created_holiday_name is not null                        as is_created_on_holiday,
        created_holiday_name,
        created_holiday_scope,

        -- durations derived from the dates
        resolution_days,
        min_resolution_hours,
        max_resolution_hours,

        -- SLA outcome from the date bounds. Undetermined when the bounds
        -- straddle the target, which covers every same-day ticket on a 4 or 8
        -- hour target.
        sla_target_hours,
        standard_sla_target_hours,
        sla_target_hours <> standard_sla_target_hours           as is_sla_target_nonstandard,
        case
            when resolved_date is null                           then 'not_resolved'
            when is_resolved_before_created                      then 'undetermined'
            when min_resolution_hours >= sla_target_hours        then 'breached'
            when max_resolution_hours <= sla_target_hours        then 'met'
            else 'undetermined'
        end                                                     as sla_outcome,

        -- supplied figures and how they compare with the dates
        supplied_resolution_hours,
        supplied_first_response_hours,
        supplied_is_sla_breached,
        supplied_resolution_hours between min_resolution_hours
                                      and max_resolution_hours as is_supplied_resolution_consistent,
        supplied_first_response_hours > max_resolution_hours   as is_first_response_after_resolution,

        -- data quality
        is_resolved_before_created,
        is_created_outside_calendar,
        is_created_before_account,
        is_resolved_outside_calendar,
        has_data_quality_issue,
        supplied_data_quality_flag

    from elapsed_bounds

)

select * from final
