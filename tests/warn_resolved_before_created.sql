{{ config(severity = 'warn') }}

-- Known defect, kept visible: tickets resolved before they were created. They
-- are flagged and excluded from durations, but the count is reported on
-- every build so a change in it gets noticed.

select
    ticket_id,
    created_date,
    resolved_date

from {{ ref('fct_tickets') }}

where resolved_date < created_date
