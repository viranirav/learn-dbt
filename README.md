# learn-dbt

A hands-on project for learning [dbt (data build tool)](https://docs.getdbt.com) using a classic HR / Employee database on a local PostgreSQL instance.

## What's inside

| Folder | Description |
|---|---|
| [`hr/`](hr/) | The dbt project — seeds, staging models, mart models, and tests |

## Architecture

Follows the **Medallion pattern** (Bronze → Silver → Gold):

```
🥉 Bronze (public)           →   🥈 Silver (public_staging)   →   🥇 Gold (public_marts)
Raw CSVs loaded via dbt seed     Cleaned & typed views              Analytical tables
```

See the [full project README](hr/README.md) for the complete diagram, folder structure, and commands.

## Quick start

```bash
# Install dependencies
uv sync

# Load seed data (Bronze)
cd hr && uv run dbt seed

# Build all models (Silver + Gold)
uv run dbt run

# Run all 22 data tests
uv run dbt test
```

## Stack

- **dbt-postgres** 1.11 via `uv`
- **PostgreSQL** 18 (Postgres.app)
- **Database:** `employee_db` on `localhost:5432`
