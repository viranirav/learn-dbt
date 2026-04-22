-- Singular test: fails if any employee earns more than their job's max_salary.
-- Returns violating rows — dbt treats any returned rows as a test failure.
select
    e.employee_id,
    e.full_name,
    e.job_id,
    e.salary,
    j.max_salary
from {{ ref('stg_employees') }} e
join {{ ref('stg_jobs') }}      j using (job_id)
where e.salary > j.max_salary
