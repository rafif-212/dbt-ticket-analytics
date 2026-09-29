-- Joining fct_tickets to all five dimensions must return every fact row
-- exactly once. A missing dimension row drops tickets from any report that
-- joins through it; a duplicated dimension key multiplies them. The
-- relationships tests catch the first case but not the second.

with fact as (

    select count(*) as fact_rows from {{ ref('fct_tickets') }}

),

joined as (

    select count(*) as joined_rows

    from {{ ref('fct_tickets') }} as f
    inner join {{ ref('dim_date') }} as created
        on f.created_date_key = created.date_key
    inner join {{ ref('dim_date') }} as resolved
        on f.resolved_date_key = resolved.date_key
    inner join {{ ref('dim_customer_account') }} as account
        on f.customer_account_id = account.customer_account_id
    inner join {{ ref('dim_assignee') }} as assignee
        on f.assignee_key = assignee.assignee_key
    inner join {{ ref('dim_category') }} as category
        on f.category_key = category.category_key
    inner join {{ ref('dim_priority') }} as priority
        on f.priority_key = priority.priority_key

)

select fact_rows, joined_rows
from fact
cross join joined
where fact_rows <> joined_rows
