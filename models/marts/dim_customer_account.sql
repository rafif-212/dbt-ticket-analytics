-- One row per customer account. Only attributes that are stable within an
-- account are kept; names, emails, segment and subscription vary from ticket
-- to ticket on the same account, so they stay off this table. If a kept
-- attribute ever varies, this produces two rows for one account and the
-- unique test on customer_account_id fails.

select distinct
    customer_account_id,
    company_name,
    account_type,
    industry,
    account_manager,
    monthly_contract_value,
    account_created_date,
    region

from {{ ref('stg_tickets') }}
