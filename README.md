# Zomato Multi-Table SQL Analysis (India)

## Overview
Analysis of a multi-table Zomato-style food delivery dataset (restaurants, 
users, orders, menu, food — linked via foreign keys) using PostgreSQL, 
focused on practicing JOINs and investigating data quality issues beyond 
single-table analysis.

## Dataset
Five related tables: `users` (customer demographics), `restaurant` 
(restaurant details, cuisine, city), `orders` (transactions linking users 
to restaurants), `menu` (restaurant-to-food linking table), `food` 
(food item catalog). Many-to-many relationship between restaurants and 
food items via `menu`.

## Analysis

**1. Which cuisine generates the most total order revenue?**
Joined `orders` to `restaurant` on `r_id = id`. Top cuisines: 
North Indian+Chinese (₹4.5Cr), Indian (₹4.26Cr), North Indian (₹3.37Cr). 
Limitation noted: combined cuisine tags (e.g., "North Indian,Chinese") 
are counted separately from single tags (e.g., "North Indian"), so true 
per-cuisine totals are understated/fragmented rather than fully combined.
Also confirmed `restaurant.cuisine` and `menu.cuisine` are exact 
duplicates (spot-checked via join) — a data redundancy, not two 
meaningfully different fields.

**2. Which city generates the most total order revenue?**
Initial ranking (grouping directly on the raw `city` column) showed 
Tirupati as the top city (₹4.25Cr). Investigation revealed the `city` 
field inconsistently mixes two formats — a plain city name for some 
rows ("Tirupati"), and "neighborhood,city" for others 
("Malviya Nagar,Delhi"). This fragmented every major metro checked 
across dozens of separate rows: Delhi (30 rows, true total ≈₹10.59Cr), 
Bangalore (32 rows, ≈₹9.33Cr), Pune (29 rows, ≈₹7.15Cr), and Ahmedabad 
(12 rows, ≈₹7.64Cr) — each genuinely larger than Tirupati's "#1" figure 
once properly combined. Confirmed this pattern held across four 
different metros before concluding naive aggregation on this column 
produces a materially wrong top-city ranking, systematically 
undercounting every major metro due to inconsistent location-field 
formatting.

**3. Who are the top-spending customers?**
Initial ranking (by total `sales_amount`) was dominated entirely by 
bulk/corporate-style orders, not genuine individual spending. Used 
percentile analysis (`PERCENTILE_CONT`) on `sales_qty` to find a 
data-driven outlier threshold (99th percentile = 215 units) rather than 
an arbitrary cutoff. After excluding orders above this threshold, total 
spend for the original #1 "top spender" dropped by ~₹7,00,000, and the 
entire top-10 list changed to a completely different set of customers — 
confirming the original ranking reflected bulk transactions, not real 
customer value. Verified the new top spenders' order counts matched 
their distinct order dates, confirming genuine repeat-purchase behavior 
(1–5 separate orders each, mostly on different days).

**4. Does spending differ by occupation?**
Average order value was nearly identical across all occupation 
categories (₹6,400–6,600 for Student, Employee, Self Employed, 
House wife) — occupation does not meaningfully predict individual 
spending behavior. Large differences in total revenue and order count 
by occupation were fully explained by population size (number of users 
per category matched order volume ranking exactly), not by underlying 
behavioral differences.

**5. Data quality check — orphaned orders**
Used a `LEFT JOIN` from `orders` to `restaurant` to find orders with no 
matching restaurant record. Investigated further and confirmed these 
aren't mismatched references (i.e., pointing to a restaurant ID that 
doesn't exist) — instead, `r_id` itself is `NULL` in the source data for 
these orders, meaning restaurant assignment was never captured at all. 
This means earlier revenue-by-cuisine analysis (which used an inner 
JOIN) silently excluded these orders, slightly undercounting true total 
revenue.

## Tools
PostgreSQL, pgAdmin, Google Colab (pandas, for CSV cleaning of restaurant csv file — fixing 
embedded newlines and inconsistent quoting before import)

## Files
- `zomato_retail.sql` — all queries, in order, with comments
