with source as (

    select * from {{ source('raw', 'nz_calendar') }}

),

renamed as (

    select
        cast(date as date)                           as calendar_date,
        {{ clean_text('national_holiday') }}         as national_holiday_name,
        cast(is_national_holiday as boolean)         as is_national_holiday,
        cast(is_weekend as boolean)                  as is_weekend,
        cast(is_business_day as boolean)             as is_business_day,
        cast(is_long_weekend_holiday as boolean)     as is_long_weekend_holiday

    from source

)

select * from renamed
