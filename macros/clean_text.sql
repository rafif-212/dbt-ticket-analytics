{#
    Trim whitespace and turn empty strings into nulls, so a blank value can't
    pass a not_null test or appear as its own category.
#}
{% macro clean_text(column_name) -%}
    nullif(trim(cast({{ column_name }} as varchar)), '')
{%- endmacro %}
