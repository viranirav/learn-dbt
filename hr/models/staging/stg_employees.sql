with legacy as (
    select
        employee_id,
        first_name,
        last_name,
        email,
        phone_number,
        hire_date,
        job_id,
        salary,
        commission_pct,
        manager_id,
        department_id,
        'full_time' as employment_type,
        false       as is_remote
    from {{ ref('employees') }}
),

new_hires as (
    select
        employee_id,
        first_name,
        last_name,
        email,
        phone_number,
        hire_date,
        job_id,
        salary,
        commission_pct,
        manager_id,
        department_id,
        employment_type,
        is_remote
    from {{ ref('new_hires') }}
),

combined as (
    select * from legacy
    union all
    select * from new_hires
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
from combined
