# What the data can't tell you

The source is synthetic: 100,851 generated service-desk tickets, cleaned in
the Ticket-analytics-pipeline project. The gaps below come from how it was
generated, not from anything this project did to it. None of them is patched.
Each one is either flagged in the models, reported by a warn-level test, or
both, and every number here comes from a file in `analyses/` or `tests/`.

## Intake stops at the end of 2024

**What.** Tickets are created every day from 1 Jul 2023 to 31 Dec 2024, then
not at all until 10 tickets on 15 Mar 2025, then nothing to 31 Mar 2025. That
leaves 89 days in 2025 with no intake (31 in January, 28 in February, 30 in
March).

**What it looks like it means, and why it doesn't.** January 2025 still has
537 resolutions, which reads at first like work carrying on while new tickets
went missing. It isn't. All 537 were resolved 1 to 14 Jan from tickets created
18 to 31 Dec, and every ticket in the data resolves within 0 to 14 days. They
are December's tickets finishing. The data can't say whether 2025 intake was
lost from the export or never generated.

**How it's handled.** The date dimension runs through every day, so the 89
days show as zeros in `fct_daily_workload` instead of disappearing.
`assert_date_dimension_is_continuous` fails the build if a day goes missing.

**Source.** `analyses/coverage_gap.sql`.

## Dates have no time of day

**What.** Every created, resolved and account date in the source is midnight.
`assert_source_timestamps_have_no_time_of_day` checks this on every build.

**What it costs.** A ticket resolved `d` days after creation took somewhere
between 24(d-1) and 24(d+1) hours, floored at zero. A ticket created and
resolved on the same day could have taken one minute or 23 hours. Any duration
in this project is a range, carried as `min_resolution_hours` and
`max_resolution_hours`.

## `resolution_time_hours` doesn't reconcile with the dates

**What.** For the 39,959 resolved tickets that pass the quality rules, the
supplied hours fall inside the range the dates allow for 5,354 (13.4%). The
correlation between the supplied hours and the days between the dates is
-0.001. The dates spread resolution evenly over 0 to 14 days; the supplied
hours spread evenly over 1 to 240 hours. With a correlation that close to
zero, the 13.4% that fit look like chance matches rather than accurate rows.

**How it's handled.** Kept as `supplied_resolution_hours` for comparison.
`is_supplied_resolution_consistent` marks the rows that fit. Durations and SLA
outcomes use the dates.

**Source.** `analyses/supplied_resolution_hours_reconciliation.sql`.

## `sla_breached` doesn't track resolution time

**What.** If the supplied flag measured SLA performance, tickets the dates
show as met would rarely be flagged, and tickets shown as breached nearly
always would. Instead the flag is set on about half of every group:

| SLA outcome from the dates | Tickets | Supplied flag says breached |
|---|---|---|
| breached | 33,857 | 50.0% |
| met | 2,031 | 50.8% |
| undetermined | 4,071 | 51.5% |
| not_resolved | 60,190 | 50.3% |

The original project noted that the flag sits near 50% and put that down to
the synthetic data. The table shows the stronger point: the flag has no
relationship with how long tickets took, so any breach rate built on it is
measuring noise.

**How it's handled.** Kept as `supplied_is_sla_breached` for comparison.
`sla_outcome` is derived from the dates instead.

**Source.** `analyses/supplied_sla_flag_vs_outcome.sql`.

## Short SLA targets can't always be settled

**What.** An SLA outcome is only settled when the whole range of possible
hours falls on one side of the target. Of the 39,959 valid resolved tickets,
4,071 (~10%) have a range that straddles their target and are `undetermined`.
For 4 and 8 hour targets that covers every ticket resolved on the day it was
created or the day after, and no ticket on those targets can be shown as met.

**How it's handled.** `sla_outcome` has an `undetermined` value rather than
guessing. A breach rate should state how many tickets it left out.

## 779 tickets have a non-standard SLA target

**What.** Each priority has a standard target (Urgent 4 hours, High 8, Medium
24, Low 48, in `seeds/priority_sla_targets.csv`). 779 tickets carry a
different one, for example an Urgent ticket with a 48 hour target. It may be a
special agreement or an entry error; the data can't say which.

**How it's handled.** SLA outcomes use the ticket's own target.
`is_sla_target_nonstandard` marks them and `warn_nonstandard_sla_target`
reports the count on every build.

## First response time can't be checked

**What.** There is no first-response timestamp, only the supplied
`first_response_time_hours`. For 2,724 valid resolved tickets, the supplied
first response comes after the latest time the ticket could have been
resolved.

**How it's handled.** Kept as `supplied_first_response_hours`, not derived.
`is_first_response_after_resolution` marks the impossible ones and
`warn_first_response_after_resolution` reports the count.

## There is no reopen history

**What.** The data has one row per ticket with its current status and no event
history, so there is nothing to count reopens from. Any reopen figure would be
invented.

**How it's handled.** Left out of the models.

## `customer_id` identifies an account, not a person

**What.** Across 5,976 IDs, one ID carries up to 400 different customer names
and 11,327 different emails, and one name appears under up to 158 IDs. Company,
region, account type, industry, account manager, contract value and account
created date never vary within an ID. Segment (up to 3 values) and
subscription type (up to 4) do.

**How it's handled.** `dim_customer_account` holds only the stable
attributes, with a unique test that fails if one starts to vary. Names and
emails aren't modelled; segment and subscription type sit on the fact table.

**Source.** `analyses/customer_id_is_an_account.sql`.

## 702 tickets fail a quality rule

**What.** The original cleaning flagged 702 tickets. Re-deriving the rules
here gives the same 702:

| Rule | Tickets |
|---|---|
| Created before the customer account existed | 674 |
| Resolved before created | 25 |
| Created date outside the calendar (1970 and 2099) | 8 |
| Resolved date outside the calendar (1970) | 1 |
| Any rule | 702 |

669 of the 702 are caught only by the account rule. Most of the flagged set is
tickets that predate their account, not tickets with broken dates of their
own.

**How it's handled.** Flagged rather than deleted. They stay in `fct_tickets`
with `has_data_quality_issue` and are excluded from `fct_daily_workload`.
`assert_quality_rules_match_supplied_flag` fails if the re-derived rules and
the original flag ever disagree.

**Source.** `analyses/quality_rule_counts.sql`.
