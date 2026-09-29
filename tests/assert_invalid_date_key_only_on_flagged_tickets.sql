-- The -1 date member is for dates that fail a quality rule. An unflagged
-- ticket landing there means a valid date fell outside the calendar (the
-- source extended past it, for example) and would drop out of every
-- date-based report without anyone noticing.

select
    ticket_id,
    created_date,
    resolved_date,
    created_date_key,
    resolved_date_key

from {{ ref('fct_tickets') }}

where (created_date_key = -1 or resolved_date_key = -1)
  and not has_data_quality_issue
