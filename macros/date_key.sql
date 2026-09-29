{#
    Integer date key in yyyymmdd form. Built from date parts rather than a
    format string so the same SQL runs on DuckDB and Snowflake.
#}
{% macro date_key(date_column) -%}
    (extract(year from {{ date_column }}) * 10000
     + extract(month from {{ date_column }}) * 100
     + extract(day from {{ date_column }}))
{%- endmacro %}
