-- How many tickets each quality rule catches, and how many are caught by that
-- rule alone. Most of the flagged set comes from one rule that is about the
-- account, not about the ticket's own dates.

select
    count(*) filter (where is_resolved_before_created)      as resolved_before_created,
    count(*) filter (where is_created_outside_calendar)     as created_outside_calendar,
    count(*) filter (where is_created_before_account)       as created_before_account,
    count(*) filter (where is_resolved_outside_calendar)    as resolved_outside_calendar,
    count(*) filter (
        where is_created_before_account
          and not is_resolved_before_created
          and not is_created_outside_calendar
          and not is_resolved_outside_calendar
    )                                                       as only_created_before_account,
    count(*) filter (where has_data_quality_issue)          as any_rule

from {{ ref('fct_tickets') }}
