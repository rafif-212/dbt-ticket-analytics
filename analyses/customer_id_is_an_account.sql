-- Why customer_id is modelled as an account rather than a person: names and
-- emails vary widely within one ID, while account attributes don't vary at
-- all (dim_customer_account's unique test enforces the second half).

with per_id as (

    select
        customer_account_id,
        count(distinct customer_name)       as names,
        count(distinct customer_email)      as emails,
        count(distinct customer_segment)    as segments,
        count(distinct subscription_type)   as subscription_types
    from {{ ref('stg_tickets') }}
    group by 1

),

per_name as (

    select customer_name, count(distinct customer_account_id) as ids
    from {{ ref('stg_tickets') }}
    group by 1

)

select
    (select count(*) from per_id)              as customer_ids,
    (select max(names) from per_id)            as max_names_per_id,
    (select max(emails) from per_id)           as max_emails_per_id,
    (select max(segments) from per_id)         as max_segments_per_id,
    (select max(subscription_types) from per_id) as max_subscription_types_per_id,
    (select max(ids) from per_name)            as max_ids_per_name
