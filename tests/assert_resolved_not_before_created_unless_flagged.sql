-- A ticket can't be resolved before it was created. 25 source tickets are,
-- and all of them carry the quality flag; warn_resolved_before_created reports
-- that count on every build. This test fails if such a ticket ever reaches the
-- mart without the flag, where it would feed a negative duration into metrics.

select
    ticket_id,
    created_date,
    resolved_date,
    has_data_quality_issue

from {{ ref('fct_tickets') }}

where resolved_date < created_date
  and not has_data_quality_issue
