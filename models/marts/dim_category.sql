select
    category                        as category_key,
    category,
    count(distinct category_raw)    as raw_spelling_count

from {{ ref('stg_tickets') }}
group by category
