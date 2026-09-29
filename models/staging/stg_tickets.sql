with source as (

    select * from {{ source('raw', 'tickets_clean') }}

),

renamed as (

    select
        cast(ticket_id as bigint)                        as ticket_id,
        -- One customer_id carries hundreds of different names, so it
        -- identifies an account, not a person.
        {{ clean_text('customer_id') }}                  as customer_account_id,

        -- account attributes
        {{ clean_text('company_name') }}                 as company_name,
        {{ clean_text('account_type') }}                 as account_type,
        {{ clean_text('industry') }}                     as industry,
        {{ clean_text('account_manager') }}              as account_manager,
        cast(monthly_contract_value as decimal(12, 2))   as monthly_contract_value,
        cast(account_created_date as date)               as account_created_date,
        {{ clean_text('region') }}                       as region,

        -- contact and per-ticket customer attributes
        {{ clean_text('customer_name') }}                as customer_name,
        {{ clean_text('customer_email') }}               as customer_email,
        {{ clean_text('billing_contact_email') }}        as billing_contact_email,
        {{ clean_text('customer_segment') }}             as customer_segment,
        {{ clean_text('subscription_type') }}            as subscription_type,
        cast(customer_tenure_months as integer)          as customer_tenure_months,
        cast(previous_tickets as integer)                as previous_ticket_count,

        -- ticket classification
        {{ clean_text('service_area') }}                 as service_area,
        {{ clean_text('category') }}                     as category_raw,
        {{ clean_text('category_clean') }}               as category,
        {{ clean_text('priority') }}                     as priority,
        cast(sla_target_hours as integer)                as sla_target_hours,
        {{ clean_text('status') }}                       as status,
        {{ clean_text('channel') }}                      as channel,
        {{ clean_text('issue_description') }}            as issue_description,
        {{ clean_text('resolution_notes') }}             as resolution_notes,
        cast(issue_complexity_score as integer)          as issue_complexity_score,
        {{ clean_text('operating_system') }}             as operating_system,
        {{ clean_text('browser') }}                      as browser,

        -- assignment
        {{ clean_text('team') }}                         as assignee_team,
        {{ clean_text('assigned_to') }}                  as assignee_name,

        -- Every source timestamp is midnight, so these are dates in practice.
        -- A singular test fails if a time of day ever appears.
        cast(ticket_created_date as date)                as created_date,
        cast(ticket_resolved_date as date)               as resolved_date,

        -- Supplied figures, kept as they are. The durations do not reconcile
        -- with the dates and the breach flag does not track resolution time,
        -- so downstream models derive their own and keep these for comparison.
        cast(first_response_time_hours as double)        as supplied_first_response_hours,
        cast(resolution_time_hours as double)            as supplied_resolution_hours,
        cast(sla_breached as boolean)                    as supplied_is_sla_breached,
        cast(data_quality_flag as boolean)               as supplied_data_quality_flag,

        cast(escalated as boolean)                       as is_escalated,
        cast(csat_score as integer)                      as csat_score

    from source

)

select * from renamed
