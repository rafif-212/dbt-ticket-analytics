-- Unassigned tickets map to the Unassigned member of dim_assignee. That is
-- only right when both the person and the team are missing. A ticket with a
-- team but no person would lose its team in the mart.

select
    ticket_id,
    assignee_name,
    assignee_team

from {{ ref('stg_tickets') }}

where (assignee_name is null) <> (assignee_team is null)
