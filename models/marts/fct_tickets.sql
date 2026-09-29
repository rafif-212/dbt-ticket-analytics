with tickets as (

    select * from {{ ref('int_tickets_enriched') }}

),

dates as (

    select date_key, calendar_date
    from {{ ref('dim_date') }}
    where date_key > 0

)

select
    tickets.ticket_id,

    -- dimension keys
    coalesce(created.date_key, -1)                     as created_date_key,
    case
        when tickets.resolved_date is null then -2
        else coalesce(resolved.date_key, -1)
    end                                                as resolved_date_key,
    tickets.customer_account_id,
    coalesce(tickets.assignee_name, 'Unassigned')      as assignee_key,
    tickets.category                                   as category_key,
    tickets.priority                                   as priority_key,

    -- dates as recorded, including the invalid ones the keys can't point to
    tickets.created_date,
    tickets.resolved_date,

    -- ticket attributes kept on the fact rather than in their own dimension
    tickets.status,
    tickets.channel,
    tickets.service_area,
    tickets.region,
    tickets.customer_segment,
    tickets.subscription_type,
    tickets.is_escalated,
    tickets.is_created_on_holiday,
    tickets.created_holiday_name,
    tickets.created_holiday_scope,

    -- measures derived from the dates
    tickets.is_resolved,
    tickets.resolution_days,
    tickets.min_resolution_hours,
    tickets.max_resolution_hours,
    tickets.sla_target_hours,
    tickets.is_sla_target_nonstandard,
    tickets.sla_outcome,
    tickets.csat_score,
    tickets.issue_complexity_score,

    -- supplied figures, for comparison only
    tickets.supplied_first_response_hours,
    tickets.supplied_resolution_hours,
    tickets.supplied_is_sla_breached,
    tickets.is_supplied_resolution_consistent,
    tickets.is_first_response_after_resolution,

    -- data quality
    tickets.has_data_quality_issue,
    tickets.is_resolved_before_created,
    tickets.is_created_outside_calendar,
    tickets.is_created_before_account,
    tickets.is_resolved_outside_calendar

from tickets
left join dates as created
    on tickets.created_date = created.calendar_date
left join dates as resolved
    on tickets.resolved_date = resolved.calendar_date
