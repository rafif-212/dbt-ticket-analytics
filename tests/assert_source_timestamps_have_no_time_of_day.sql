-- stg_tickets casts the source timestamps to dates, and every duration in this
-- project is counted in whole days. That is only safe while every timestamp is
-- midnight. If a later extract carries a time of day, this fails so the cast
-- and the duration logic get revisited instead of silently dropping the time.

select
    ticket_id,
    ticket_created_date,
    ticket_resolved_date,
    account_created_date

from {{ source('raw', 'tickets_clean') }}

where ticket_created_date <> date_trunc('day', ticket_created_date)
   or ticket_resolved_date <> date_trunc('day', ticket_resolved_date)
   or account_created_date <> date_trunc('day', account_created_date)
