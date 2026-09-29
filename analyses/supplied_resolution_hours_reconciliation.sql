-- How far the supplied resolution_time_hours sits from what the dates allow,
-- for resolved tickets that pass the quality rules.

with resolved as (

    select *
    from {{ ref('fct_tickets') }}
    where is_resolved
      and not has_data_quality_issue

)

select
    count(*)                                                       as resolved_tickets,
    count(*) filter (where is_supplied_resolution_consistent)      as consistent_with_dates,
    round(100.0 * count(*) filter (where is_supplied_resolution_consistent)
          / count(*), 1)                                           as pct_consistent,
    round(corr(supplied_resolution_hours, resolution_days * 24), 3) as correlation_with_dates,
    min(resolution_days)                                           as min_days_by_dates,
    max(resolution_days)                                           as max_days_by_dates,
    round(min(supplied_resolution_hours), 1)                       as min_supplied_hours,
    round(max(supplied_resolution_hours), 1)                       as max_supplied_hours

from resolved
