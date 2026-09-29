-- The supplied sla_breached flag against the SLA outcome the dates support.
-- If the flag tracked resolution time, tickets the dates show as met would
-- rarely be flagged and tickets shown as breached would nearly always be.

select
    sla_outcome,
    count(*)                                                  as tickets,
    round(100.0 * avg(case when supplied_is_sla_breached then 1 else 0 end), 1)
                                                              as pct_supplied_flag_breached

from {{ ref('fct_tickets') }}
where not has_data_quality_issue

group by 1
order by 1
