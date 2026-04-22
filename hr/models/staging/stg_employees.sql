with source as (
    select * from {{ ref('employees') }}
)

select
    employee_id,
    first_name,
    last_name,
    first_name || ' ' || last_name  as full_name,
    lower(email)                    as email,
    phone_number,
    hire_date,
    job_id,
    salary,
    coalesce(commission_pct, 0)     as commission_pct,
    manager_id,
    department_id,
    employment_type,
    is_remote
from source
