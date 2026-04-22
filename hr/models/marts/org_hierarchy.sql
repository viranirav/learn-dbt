-- Flattens manager → direct report relationships one level deep.
-- Each row = one employee with their manager's name and department.
with employees as (
    select * from {{ ref('stg_employees') }}
),

departments as (
    select * from {{ ref('stg_departments') }}
)

select
    e.employee_id,
    e.full_name                     as employee_name,
    d.department_name,
    m.employee_id                   as manager_id,
    m.full_name                     as manager_name,
    m.job_id                        as manager_job_id,
    e.hire_date,
    e.salary
from employees e
left join employees m on e.manager_id = m.employee_id
left join departments d on e.department_id = d.department_id
order by d.department_name, m.full_name, e.full_name
