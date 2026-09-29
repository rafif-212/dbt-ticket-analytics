{{ config(severity = 'warn') }}

-- Known defect, kept visible: tickets whose SLA target differs from the
-- standard for their priority. It may be a special agreement or an entry
-- error; the data can't say which, so SLA outcomes use the ticket's own target
-- and the count is reported on every build.

select
    ticket_id,
    priority_key,
    sla_target_hours

from {{ ref('fct_tickets') }}

where is_sla_target_nonstandard
