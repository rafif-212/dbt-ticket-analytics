-- Resolved and Closed tickets have a resolved date; Open, In Progress and
-- Pending Customer tickets don't. Every duration and SLA figure relies on
-- this. A resolved ticket with no date would count as not_resolved, and an
-- open ticket with a date would get a resolution time it doesn't have.

select
    ticket_id,
    status,
    resolved_date

from {{ ref('fct_tickets') }}

where (status in ('Resolved', 'Closed') and resolved_date is null)
   or (status not in ('Resolved', 'Closed') and resolved_date is not null)
