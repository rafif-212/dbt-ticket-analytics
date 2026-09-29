-- The quality rules in int_tickets_enriched re-derive the original project's
-- data_quality_flag. Any ticket where the two disagree means either the rules
-- have drifted or the source was re-cleaned differently, and both need a look
-- before the flagged set is trusted.

select
    ticket_id,
    has_data_quality_issue,
    supplied_data_quality_flag,
    is_resolved_before_created,
    is_created_outside_calendar,
    is_created_before_account,
    is_resolved_outside_calendar

from {{ ref('int_tickets_enriched') }}

where has_data_quality_issue <> supplied_data_quality_flag
