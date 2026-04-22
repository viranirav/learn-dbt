with source as (
    select * from {{ ref('departments') }}
)

select
    department_id,
    department_name,
    location_id
from source
