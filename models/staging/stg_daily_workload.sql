with source as (

    select * from {{ source('raw', 'daily_workload') }}

),

renamed as (

    select
        cast(date as date)                   as workload_date,
        cast(tickets_opened as integer)      as tickets_opened,
        cast(open_backlog as integer)        as open_backlog

    from source

)

select * from renamed
