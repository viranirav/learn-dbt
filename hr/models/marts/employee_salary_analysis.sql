with employees as (
    select * from {{ ref('stg_employees') }}
),

jobs as (
    select * from {{ ref('stg_jobs') }}
),

departments as (
    select * from {{ ref('stg_departments') }}
)

select
    e.employee_id,
    e.full_name,
    d.department_name,
    j.job_title,
    e.salary,
    j.min_salary,
    j.max_salary,
    j.salary_band_width,
    -- how far through the salary band this employee sits (0 = min, 1 = max)
    round(
        (e.salary - j.min_salary)::numeric / nullif(j.salary_band_width, 0),
        2
    )                                                           as salary_band_position,
    -- annual total compensation including commission
    round((e.salary * 12 * (1 + e.commission_pct))::numeric, 2) as annual_total_comp,
    e.hire_date,
    date_part('year', age(e.hire_date))                        as years_at_company
from employees e
join jobs      j using (job_id)
join departments d using (department_id)
order by annual_total_comp desc
