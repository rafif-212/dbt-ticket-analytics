{{ config(severity = 'warn') }}

-- Known defect, kept visible: the supplied first response hours come after
-- the latest time the ticket could have been resolved. There is no
-- first-response timestamp to correct against, so these are reported, not
-- changed.

select
    ticket_id,
    resolution_days,
    max_resolution_hours,
    supplied_first_response_hours

from {{ ref('fct_tickets') }}

where is_first_response_after_resolution
  and not has_data_quality_issue
