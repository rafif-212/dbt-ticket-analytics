select
    priority                    as priority_key,
    priority,
    priority_rank,
    standard_sla_target_hours

from {{ ref('priority_sla_targets') }}
