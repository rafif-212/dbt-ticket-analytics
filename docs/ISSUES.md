# Issues found and corrected

Every problem found during the build, including mistakes in my own plan,
with the fix and what catches it if it happens again.

## The quality flag was described as "impossible dates"

**Found by.** Checking the model plan against the flag definition in the
original project's `02_cleaning.ipynb`.

**What happened.** The plan summarised the 702 flagged tickets as tickets
with impossible dates. The original flag has four rules, and 669 of the 702
are caught only by "created before the customer account existed", which is
about the account rather than the ticket's own dates. Rules written from the
summary would have flagged 33 tickets and missed the rest.

**Fix.** `int_tickets_enriched` implements all four rules as separate
columns, and DATA_GAPS.md gives the count for each.

**How a repeat is caught.** `assert_quality_rules_match_supplied_flag` fails
if the re-derived flag disagrees with the original on any ticket. As a check,
the account rule was removed temporarily and the test failed on 669 tickets.

## SLA breach was first planned as a yes/no flag from whole days

**Found by.** Reviewing the plan against the timestamps, which are all
midnight.

**What happened.** The first plan derived a breach flag from days between
dates times 24. With no time of day, that calls every same-day ticket met and
every next-day Urgent ticket breached, when a same-day ticket could have taken
anything from one minute to 23 hours.

**Fix.** Durations are carried as a minimum and maximum number of hours, and
`sla_outcome` is `undetermined` when that range straddles the target.

**How a repeat is caught.** `assert_source_timestamps_have_no_time_of_day`
fails if the source gains a time of day, which is the point where this logic
should be revisited.

## January 2025 resolutions were read as work continuing through the gap

**Found by.** `analyses/coverage_gap.sql`, while writing DATA_GAPS.md.

**What happened.** During profiling, 537 resolutions in January 2025 with no
new tickets were read as a sign that 2025 intake had gone missing from the
export. The monthly breakdown shows all 537 were resolved 1 to 14 Jan, from
tickets created 18 to 31 Dec. Every ticket resolves within 0 to 14 days, so
these are December's tickets finishing and say nothing about why intake stops.

**Fix.** DATA_GAPS.md says the data can't tell whether 2025 intake was lost
or never generated.

**How a repeat is caught.** The analysis puts monthly resolutions next to
monthly intake, so the same misreading is visible to anyone who reruns it.

## SLA breach rates were built on a flag that doesn't track resolution time

**Found by.** Profiling for this project: breach rate by days to resolve is
~50% whether a ticket took under a day or over a week.

**What happened.** The original project noted that `sla_breached` sits near
50% and put it down to the synthetic data, but its agent notebook still
reported breach rates by team from it. The flag has no relationship with how
long tickets took, so those rates measure noise.

**Fix.** Here the flag is kept only as `supplied_is_sla_breached`, and SLA
figures come from `sla_outcome`. The original project is unchanged by this
repo.

**How a repeat is caught.** Nothing fails the build, since the flag is
supplied data rather than a model error. `analyses/supplied_sla_flag_vs_outcome.sql`
shows the comparison whenever it is run.

## Date differences used a DuckDB-only function

**Found by.** Writing the Snowflake portability note in DECISIONS.md.

**What happened.** `int_tickets_enriched` and the date continuity test used
DuckDB's `date_diff('day', a, b)`, which doesn't carry over to Snowflake in
that form.

**Fix.** Both use dbt's `dbt.datediff` macro, which compiles to the right SQL
for each adapter.

**How a repeat is caught.** Nothing automatic; there is no Snowflake target
to build against. It is listed in DECISIONS.md with the functions still
unchecked.

## dbt's usage ID file was committed

**Found by.** Reading the file list of the project-setup commit.

**What happened.** The first `dbt debug` wrote `.user.yml`, an anonymous
usage ID, into the project folder, and it went into the commit.

**Fix.** Removed from the commit before it was pushed and added to
`.gitignore`.

**How a repeat is caught.** `.gitignore` excludes it.
