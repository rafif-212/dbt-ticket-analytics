# Decisions

One section per decision, with what was rejected and why.

## Why DuckDB rather than Postgres

**Decision.** DuckDB as the warehouse, through the dbt-duckdb adapter.

**Alternatives considered.** Postgres in Docker; a Snowflake trial account.

**Why.** DuckDB is a single file with no server, so a reviewer can clone,
load and build without installing a database. Postgres would add a container
for no modelling benefit at ~100k rows. Snowflake would need credentials a
reviewer doesn't have.

**Trade-off.** DuckDB SQL differs from Snowflake in places. The models use
dbt's cross-database `datediff` macro and build date keys from date parts
rather than format strings, so the main logic should port. They have not been
run on Snowflake. `monthname`, `dayname` and `extract(isodow ...)` in
`dim_date` would need checking, and the queries in `analyses/` use DuckDB's
`filter` clause, which Snowflake doesn't support.

## Why the fact table is at ticket grain

**Decision.** `fct_tickets` has one row per ticket, 100,851 rows.

**Alternatives considered.** One row per ticket status change; one row per
ticket per day.

**Why.** The source has one row per ticket with its current status and no
event history, so there is nothing finer to model. A daily snapshot grain
would have to invent each ticket's status on days the data says nothing about.
Daily volume questions go to `fct_daily_workload` instead, which is one row
per day built from the same tickets.

**Trade-off.** Questions about how tickets moved between statuses, or how
often they were reopened, can't be answered. See DATA_GAPS.md.

## Why these materialisations

**Decision.** Staging and intermediate models are views; marts are tables.

**Alternatives considered.** Ephemeral intermediate models; tables
throughout.

**Why.** Views cost nothing to build and always reflect the current raw
tables, which suits layers that exist to be read by the next layer. The
intermediate models are views rather than ephemeral because dbt can't run
tests against an ephemeral model, and `int_tickets_enriched` carries the
quality rules the flag-match test checks. Marts are tables because they are
what reports query.

**Trade-off.** Every mart rebuild re-runs the staging and intermediate SQL.
At this size a full `dbt build` takes a few seconds, so it doesn't matter
here.

## Why flagged tickets stay in the fact table

**Decision.** The 702 tickets that fail a quality rule stay in `fct_tickets`
with `has_data_quality_issue = true`.

**Alternatives considered.** Filtering them out in the intermediate layer;
moving them to a separate quarantine table.

**Why.** The original project flagged them rather than deleting them, and
this keeps the two projects' ticket counts the same. Keeping every ticket also
means the fan-out test can compare the mart against staging with no
exceptions. Anyone who wants to know about the bad rows can find them next to
the good ones.

**Trade-off.** Every duration or SLA figure has to filter on the flag. The
column description on `fct_tickets` says so, and `fct_daily_workload` already
excludes them.

## Why SLA outcome has an "undetermined" value

**Decision.** `sla_outcome` is `met`, `breached`, `undetermined` or
`not_resolved`, worked out from the range of hours the dates allow.

**Alternatives considered.** Using the supplied `sla_breached` flag; a
yes/no flag from whole days times 24.

**Why.** The supplied flag doesn't track resolution time (DATA_GAPS.md). A
yes/no flag from whole days would call every same-day ticket met and every
next-day Urgent ticket breached, when the dates can't support either. The
third value says so instead of guessing.

**Trade-off.** Breach rates need to state how many tickets were
undetermined, which makes them less tidy to report.

## Why special date members rather than null keys

**Decision.** `dim_date` has a -1 member for invalid dates and a -2 member
for tickets not yet resolved. Fact rows point there instead of carrying a
null key.

**Alternatives considered.** Null foreign keys; dropping tickets whose dates
don't join.

**Why.** Every fact row then joins to every dimension, which the brief asks
the tests to prove. A null key would drop the ticket from any report that
inner-joins the date dimension. A separate test checks that only flagged
tickets land on -1, so a valid date falling outside the calendar can't hide
there.

**Trade-off.** Reports that list dates need to exclude the two special
members.

## Why natural keys rather than surrogate keys

**Decision.** Dimensions are keyed on natural values: category name, priority
name, assignee name, customer ID. Only the date uses an integer key.

**Alternatives considered.** Hashed surrogate keys from the `dbt_utils`
package.

**Why.** Every dimension here has a stable natural key, and none tracks
history, so a surrogate adds a column without protecting against anything.
Staying off packages also keeps the build to `dbt build` with no `dbt deps`
step.

**Trade-off.** If a name changed in the source, fact rows would need
re-keying. With slowly changing dimensions out of scope, that can't happen
here.

## Why regional holidays are a flag on the fact

**Decision.** `fct_tickets` carries `is_created_on_holiday`,
`created_holiday_name` and `created_holiday_scope`, matched on region and
created date in the intermediate layer.

**Alternatives considered.** A holiday dimension keyed on the region-date
string, which is how the Power BI model related the two tables.

**Why.** Most tickets don't fall on a holiday, so that relationship would be
empty for most rows and break the rule that every fact row joins to every
dimension. National holidays are also on `dim_date`, where they don't depend
on region.

**Trade-off.** This is the one place the star schema differs from the Power
BI model.

## Why a seed for SLA targets

**Decision.** The standard SLA target for each priority lives in
`seeds/priority_sla_targets.csv`, and `dim_priority` is built from it.

**Alternatives considered.** Hardcoding the four targets in SQL; taking the
most common target per priority from the data.

**Why.** The targets are a business rule, so they belong in one visible file
rather than inside a `case` statement. Deriving them from the data would let a
drift in the source quietly change the standard it is being checked against.

**Trade-off.** A change to the standard needs a change to the CSV. That is
the point.

## Why the quality rules use the calendar range, not fixed dates

**Decision.** A ticket is flagged when its created or resolved date falls
outside the calendar table, rather than outside the original project's fixed
bounds (1 Jul 2023 and 15 Jul 2026).

**Alternatives considered.** Copying the fixed dates from the original
cleaning notebook.

**Why.** A date outside the calendar can't join to the date dimension, so the
calendar is the bound that matters to the model. Fixed dates would need a code
change every time the data was extended. On the current data both versions
flag the same 702 tickets, which `assert_quality_rules_match_supplied_flag`
checks.

**Trade-off.** A ticket dated between 1 Apr 2025 and 15 Jul 2026 would be
flagged here but not in the original. None exist, and if one appeared, the
flag-match test would fail and point at it.

## Why the source is pinned to one commit

**Decision.** `load_data.py` downloads the Parquet files from a fixed commit
of Ticket-analytics-pipeline, not from `main`.

**Alternatives considered.** Downloading from `main`; committing the files to
this repo.

**Why.** Pinning means a later change to the other project can't silently
change what this one builds on. Committing the files would break the rule of
no raw data in the repo.

**Trade-off.** Picking up new source data needs a one-line change to the
commit hash.

## What was left out

- **Reopen count.** The data has no event history (DATA_GAPS.md).
- **Derived first response time.** There is no first-response timestamp; the
  supplied figure is carried as it is.
- **Snapshots and incremental models.** The source is a static extract, so
  there is nothing to track over time or load in increments.
- **Orchestration.** One `dbt build` is the whole pipeline.
- **A BI layer.** The Power BI report already exists in the original project.
- **dbt packages.** Nothing here needed `dbt_utils` or `dbt_expectations`
  enough to add a `dbt deps` step.
- **Snowflake.** DuckDB only, for the reasons above.
