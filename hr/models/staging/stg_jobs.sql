with source as (
    select * from {{ ref('jobs') }}
)

select
    job_id,
    job_title,
    min_salary,
    max_salary,
    max_salary - min_salary as salary_band_width
from source
