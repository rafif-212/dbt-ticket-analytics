-- fct_tickets is one row per ticket. If a join upstream fans out (a holiday
-- table with two rows for one region and date, say), ticket counts and every
-- sum built on them silently double. If a filter creeps in, tickets vanish.
-- Either way the mart stops matching the distinct tickets in staging.

with staged as (

    select count(distinct ticket_id) as staged_tickets
    from {{ ref('stg_tickets') }}

),

mart as (

    select count(*) as mart_rows
    from {{ ref('fct_tickets') }}

)

select staged_tickets, mart_rows
from staged
cross join mart
where staged_tickets <> mart_rows
