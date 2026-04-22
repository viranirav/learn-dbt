# HR dbt Project

A learning project to explore dbt (data build tool) using a classic HR / Employee database.
Built on a local PostgreSQL instance with 107 employees across departments, jobs, and office locations.

---

## Medallion Architecture (Bronze → Silver → Gold)

This project follows the **Medallion pattern** — a layered approach where data gets progressively cleaner and more analytical as it moves through the pipeline.

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                         MEDALLION ARCHITECTURE                                   ║
╠══════════════╦══════════════════════════╦══════════════════════════════════════╣
║   🥉 BRONZE  ║       🥈 SILVER          ║            🥇 GOLD                   ║
║   Raw Data   ║   Cleaned & Typed        ║        Analytical / Served           ║
║─────────────────────────────────────────────────────────────────────────────────║
║  schema:     ║  schema:                 ║  schema:                             ║
║  public      ║  public_staging          ║  public_marts                        ║
║              ║                          ║                                      ║
║  employees   ║  stg_employees ────────► ║  dept_headcount                      ║
║  (CSV seed)  ║    full_name derived     ║    headcount + payroll per dept      ║
║              ║    email lowercased      ║                                      ║
║  new_hires   ║    commission null → 0   ║  employee_salary_analysis            ║
║  (CSV seed)  ║    union with new_hires  ║    salary vs band, annual comp       ║
║              ║    adds employment_type  ║                                      ║
║  departments ║    adds is_remote        ║  org_hierarchy                       ║
║  (CSV seed)  ║                          ║    manager → report tree             ║
║              ║  stg_departments ──────► ║                                      ║
║  jobs        ║    pass-through          ║                                      ║
║  (CSV seed)  ║                          ║                                      ║
║              ║  stg_jobs ─────────────► ║                                      ║
║  locations   ║    + salary_band_width   ║                                      ║
║  (CSV seed)  ║                          ║                                      ║
║              ║  stg_locations ────────► ║                                      ║
║              ║    pass-through          ║                                      ║
╠══════════════╬══════════════════════════╬══════════════════════════════════════╣
║  Stored as:  ║  Stored as:              ║  Stored as:                          ║
║  Tables      ║  Views (no storage cost) ║  Tables (fast reads)                 ║
╠══════════════╬══════════════════════════╬══════════════════════════════════════╣
║  dbt seed    ║  dbt run                 ║  dbt run                             ║
╚══════════════╩══════════════════════════╩══════════════════════════════════════╝
```

### What each layer means

| Layer | Also called | Purpose | Stored as |
|---|---|---|---|
| **Bronze** | Raw / Source | Land the data exactly as-is — no transformations | Tables (seeds) |
| **Silver** | Staging | Clean, type-cast, rename, fill nulls, union sources | Views |
| **Gold** | Marts / Serving | Join and aggregate into business-ready answers | Tables |

**Why this layering?**
- If a source format changes, you fix it once in Silver — Gold models are unaffected
- Gold models are always fast to query (pre-computed tables, not live joins)
- Each layer is independently testable

---

## Commands — Populating Each Layer

### Bronze — load CSVs into PostgreSQL
```bash
uv run dbt seed
```
Loads all `seeds/*.csv` into the `public` schema. Use `--full-refresh` to drop and reload:
```bash
uv run dbt seed --full-refresh
```

### Silver — build staging views
```bash
uv run dbt run --select staging.*
```
Creates views in `public_staging`. Reads from Bronze seeds via `{{ ref('employees') }}`.

### Gold — build mart tables
```bash
uv run dbt run --select marts.*
```
Creates tables in `public_marts`. Reads from Silver views via `{{ ref('stg_employees') }}`.

### All layers at once
```bash
uv run dbt build
```
Runs seed → run → test in dependency order. The recommended way to do a full refresh.

### Run tests only
```bash
uv run dbt test
```

### Run a single model
```bash
uv run dbt run --select dept_headcount
uv run dbt run --select stg_employees
```

---

## Adding New Employees (Extended Schema)

When new hires have additional fields (e.g. `employment_type`, `is_remote`), add them as a separate seed rather than modifying the original CSV. The staging layer unions them transparently.

**Steps:**
1. Add rows to `seeds/new_hires.csv`
2. Run `uv run dbt seed --select new_hires`
3. Run `uv run dbt run --select stg_employees+` (the `+` rebuilds all downstream models too)
4. Run `uv run dbt test`

See [seeds/new_hires.csv](seeds/new_hires.csv) and [models/staging/stg_employees.sql](models/staging/stg_employees.sql).

---

## Project Folder Structure

```
hr/
├── seeds/                    🥉 BRONZE — raw CSV files loaded into PostgreSQL
│   ├── employees.csv             Original 107 employees (classic HR schema)
│   ├── new_hires.csv             New employees with extended fields (employment_type, is_remote)
│   ├── departments.csv           27 departments
│   ├── jobs.csv                  19 job titles with min/max salary bands
│   ├── locations.csv             14 office locations
│   └── schema.yml                Column types for each CSV
│
├── models/
│   ├── staging/              🥈 SILVER — one view per source, cleans raw data
│   │   ├── stg_employees.sql     Unions employees + new_hires, normalises fields
│   │   ├── stg_departments.sql
│   │   ├── stg_jobs.sql          Adds salary_band_width derived column
│   │   ├── stg_locations.sql
│   │   └── schema.yml            Column descriptions + data tests (unique, not_null, FK)
│   │
│   └── marts/                🥇 GOLD — analytical tables for reporting
│       ├── dept_headcount.sql             Headcount, avg/min/max salary, total payroll per dept
│       ├── employee_salary_analysis.sql   Salary vs band position, annual comp, tenure
│       ├── org_hierarchy.sql              Manager → direct report tree
│       └── schema.yml
│
├── tests/                    Custom SQL tests (singular tests — beyond schema.yml generics)
│   └── assert_salary_within_band.sql     Asserts no employee earns above their job's max_salary
│
├── macros/                   Reusable Jinja snippets (empty — used as project grows)
├── analyses/                 Ad-hoc SQL tracked in version control but not run by dbt
├── snapshots/                Slowly-changing dimension tracking (e.g. salary history over time)
├── dbt_project.yml           Project config — paths, materializations per layer
└── README.md                 This file
```

### Key config: `dbt_project.yml`
Controls materialisation per folder:
```yaml
models:
  hr:
    staging:
      +materialized: view    # Silver = lightweight views (no storage cost)
    marts:
      +materialized: table   # Gold = physical tables (fast reads)
```

---

## Data Tests

### Generic tests (defined in `schema.yml`)
Run automatically on `dbt test`:

| Test | What it checks |
|---|---|
| `unique` | No duplicate values in a column |
| `not_null` | No null values |
| `relationships` | FK integrity (every `job_id` in employees exists in jobs) |

### Custom singular tests (defined in `tests/*.sql`)
Plain SQL — the test **fails if the query returns any rows**:

| Test file | Business rule it enforces |
|---|---|
| `assert_salary_within_band.sql` | No employee salary exceeds their job's `max_salary` |

Run all tests:
```bash
uv run dbt test
```

Run a specific test file:
```bash
uv run dbt test --select assert_salary_within_band
```

---

## Connection

- **Database:** `employee_db` on `localhost:5432`
- **User:** `nvira` (Postgres.app)
- **Profile config:** `~/.dbt/profiles.yml` (not committed — contains local credentials)
