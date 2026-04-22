with employees as (
    select * from {{ ref('stg_employees') }}
),

departments as (
    select * from {{ ref('stg_departments') }}
),

locations as (
    select * from {{ ref('stg_locations') }}
)

select
    d.department_id,
    d.department_name,
    l.city,
    l.country,
    count(e.employee_id)                          as headcount,
    round(avg(e.salary), 2)                       as avg_salary,
    min(e.salary)                                 as min_salary,
    max(e.salary)                                 as max_salary,
    round(sum(e.salary), 2)                       as total_payroll
from departments d
left join employees e using (department_id)
left join locations l using (location_id)
group by 1, 2, 3, 4
order by headcount desc
