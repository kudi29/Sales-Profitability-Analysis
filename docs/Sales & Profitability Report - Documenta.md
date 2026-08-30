Sales & Profitability Report - Documentation
Combined documentation for all three pages of the Power BI report: Executive Overview, Discount Analysis, and Product & Category Performance.
________________________________________
Page 1 - Executive Overview
Purpose
Give a senior stakeholder the full profitability story in under 10 seconds: is the business growing, is it profitable, where's the risk, and is anything urgent enough to need attention right now.
Business questions this page answers
•	Are sales and profit growing or shrinking, and by how much vs. last year?
•	Is the company keeping more profit from its sales over time, or less?
•	Which product categories drive the business?
•	Is there anything urgent that needs attention right now?
Data sources
Object	Role
gold.dim_date	Date dimension, marked as Date Table on full_date. Drives all time intelligence and the Year/Quarter slicers.
gold.dim_product	Product dimension. Drives the "Sales by Category" chart via category_name.
reports.vw_profit_by_category	Order-line grain fact view. Source for Total Sales, Total Profit, Total Orders, Total Customers, and the category breakdown.
KPI cards
Card	Primary value	Reference label	Conditional color
Total Sales	Total Sales	Total Sales YoY %	Total Sales YoY Color
Total Profit	Total Profit	Total Profit YoY %	Total Profit YoY Color
Profit Margin %	Profit Margin %	Profit Margin % Change (pp)	Profit Margin Change Color
Total Orders	Total Orders	—	—
Total Customers	Total Customers	—	—
Formatting decisions
•	Weighted margin, not averaged ratio. Profit Margin % is SUM(profit) / SUM(sales), not an average of individual order margins, so a $5 order and a $50,000 order aren't given equal weight.
•	Percentage-point framing for margin change, not percent-of-percent.
•	Single-axis margin trend, replacing an earlier dual-axis sales+profit line chart where profit was visually crushed by sales' much larger scale.
•	Sequential single-hue category chart (light-to-dark teal by value).
•	Alert threshold set at 0.5 percentage points — a move of that size against an ~$12M single-year revenue base already represents a five/six-figure swing in profit, worth surfacing without firing on every minor wobble.
Known data limitation - 2018 excluded from Year slicer
gold.dim_date confirms 2018 contains only 37 days of data (2018-01-01 through 2018-02-06). It is excluded from the Year slicer via a basic filter on dim_date[year] (2015/2016/2017 only), remains part of the underlying model, and is documented with an on-canvas note. Default selection: Year = 2017 (most recent complete year).
________________________________________
Page 2 - Discount Analysis
Purpose
Show how discounting affects profit margin, and whether any discount tier is actually worth offering compared to charging full price.
Business questions this page answers
•	How does profit margin change as discount rate increases?
•	Which discount bands are used most heavily?
•	Is any discount tier actually worth it, compared to no discount at all?
•	Which combination of high volume + low margin deserves review first?
Data sources
Object	Role
gold.dim_date	Date dimension. Drives the Year slicer.
gold.dim_product	Product dimension. Drives the Product Category slicer.
reports.vw_discount_impact	Order-line grain fact view, pre-bucketed into discount_band with a discount_band_sort column for correct ordering. Source for every measure on this page.
KPI cards
Card	Measure	Notes
Discounted Sales	Discount Band Sales	Formatted as currency
Avg Discount Amount	Avg Discount Amount	Average $ discount per order line
Avg Profit Margin	Profit Margin %	Weighted margin across all orders in context
No-Discount Baseline (2017)	No Discount Baseline %	Fixed reference value — see Known Limitations
Formatting decisions
•	Bands sorted by discount_band_sort, ascending, not by value, so every visual reads left-to-right from 0% to Above 30%.
•	A dashed reference line at the no-discount baseline, instead of a separate margin-lift chart, shows how each band compares to full price in a single, clear picture.
•	Order Count paired directly beside the margin chart, so a low-margin band can be read alongside how much volume runs through it.
•	Dynamic subtitle showing the active category and year filter at all times, preventing a filtered view from being mistaken for company-wide numbers.
•	Product Category slicer defaults to "All."
Known limitations
•	No-Discount Baseline is a fixed value, not dynamic. No Discount Baseline % is hardcoded to 13.6% (the correct value for 2017) and does not recalculate for other Year/Category selections. Labeled explicitly as "(2017)" to avoid implying it's live.
•	"Above 30%" discount band has no data in the current dataset years (2015–2017). The band is defined correctly in SQL and will populate if such data exists; its absence here reflects the data, not an error.
•	2018 is excluded from the Year slicer for the same reason as Page 1.
________________________________________
Page 3 - Product & Category Performance
Purpose
Show which products and categories genuinely drive profit — not just which ones generate the most sales — and let category performance be judged relative to the business as a whole rather than in isolation.
Business questions this page answers
•	Which products contribute the most actual profit, not just revenue?
•	Which categories are large but underperforming on margin, and which are small but healthy?
•	Is a given department's margin genuinely a problem, or does it just look that way because the department is small?
•	Where should investment or review be prioritized based on real profit contribution?
Data sources
Object	Role
gold.dim_date	Date dimension. Drives the Year slicer.
gold.dim_product	Product dimension. Drives category/department grouping and the Product Category slicer.
reports.vw_profit_by_category	Order-line grain fact view. Source for sales, profit, margin, and quantity by product and category.
KPI cards
Card	Measure
Total Sales	Total Sales
Total Profit	Total Profit
Overall Margin	Profit Margin %
Best Margin Category	Best Margin Category
Visuals
•	Category Profitability bubble chart — X-axis: Category Sales, Y-axis: Category Margin %, bubble size: Category Profit, color: conditional on Margin vs Company Avg (teal = at/above average, coral = below average). Encodes materiality, profitability, and profit contribution in a single view, replacing an earlier sales-only treemap.
•	Top 10 Products by Profit table — ranked using Product Rank by Profit, showing sales, profit, and margin per product. Ranked by profit rather than sales, so high-revenue/low-margin products don't crowd out genuinely profitable ones.
•	Department & Category table — sales, profit, margin, and % of Total Sales per department, with font-color conditional formatting on margin driven by Margin vs Company Avg rather than the raw margin number.
Formatting decisions
•	Bubble chart color driven by Margin vs Company Avg, not raw margin — this is the core fix for the original report's biggest flaw on this page: a small department could show an alarming margin number purely due to size. Comparing against the company average instead separates "this is genuinely underperforming" from "this is just a small number."
•	% of Total Sales placed directly beside margin in the Department & Category table, so materiality context always travels with any conditional formatting — a department flagged red can be immediately checked against how much of the business it represents.
•	Top 10 table ranked by profit, not sales, directly answering the business's actual profitability question rather than a popularity question.
•	No conditional margin coloring on the Top 10 Products table — it's already a pre-filtered list of top performers by profit, so adding red/green margin coloring on top would add noise rather than clarity (a high-volume, lower-margin bestseller could confusingly show coral right next to a "top performer" label).
Known limitations
•	Same 2018 exclusion as Pages 1 and 2.
•	Regional/location-based product performance (dim_location, vw_profit_by_region) is out of scope for this page and this report, by deliberate design decision — see project-level scope notes.
________________________________________

