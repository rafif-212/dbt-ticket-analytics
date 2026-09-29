with source as (

    select * from {{ source('raw', 'nz_holiday_days') }}

),

renamed as (

    select
        {{ clean_text('region_date') }}      as region_date_key,
        {{ clean_text('region') }}           as region,
        cast(date as date)                   as holiday_date,
        {{ clean_text('holiday_name') }}     as holiday_name,
        {{ clean_text('scope') }}            as holiday_scope

    from source

)

select * from renamed
