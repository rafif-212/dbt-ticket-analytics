-- One row per assignee with their team. A person appearing under two teams
-- produces two rows and fails the unique test on assignee_key.

with assignees as (

    select distinct
        assignee_name,
        assignee_team

    from {{ ref('stg_tickets') }}
    where assignee_name is not null

)

select
    assignee_name   as assignee_key,
    assignee_name,
    assignee_team

from assignees

union all

-- 2,017 tickets have no assignee and no team. They point here rather than
-- carrying a null key.
select
    'Unassigned',
    'Unassigned',
    'Unassigned'
