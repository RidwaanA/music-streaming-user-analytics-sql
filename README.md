# Music Streaming User Engagement & Revenue Performance Analysis

## Project Overview
Analyzed **user engagement**, **content consumption**, **and revenue performance** for a global music platform (**Don Beats**) **across 24 countries and 53 cities**.

The project delivers **actionable insights on genre popularity, artist dominance, and customer spending behavior** to s**upport recommendation systems and artist acquisition decisions**.

## Business Problem
Leadership needed clarity on:

- Which genres and artists drive engagement and revenue
- How preferences vary across countries
- Where to focus content acquisition and promotions

## Data Overview
- 59 customers, 412 invoices, 347 albums
- Presence across 53 cities / 24 countries
- Key data: `customers`, `artists`, `albums`, `tracks`, `playlists`, `invoices`

## Tools & Technologies
- MySQL
- SQL (joins, aggregations, window functions, ranking, CTEs)

## SQL Highlights
```sql
// Top Genres by Country (User Preference Segmentation)
select * 
from (
	select
		billing_country as country,
		G.genre_id,
		G.genre_name,
		count(I.invoice_id) as num_of_invoices,
		rank() over (partition by billing_country order by count(invoice_id) desc) as ranking
	from tracks
		join genre G using(genre_id)
			join invoice_items using(track_id)
				join invoice I using(invoice_id)
	group by 1,2,3) ranked
where ranking <= 3;
```
```sql
// Artist Market Share by Country (Dominance Analysis)
with purchases as (
	select
		billing_country,
		AR.artist_id,
		artist_name,
		track_id,
		count(*) over (partition by billing_country, AR.artist_id, artist_name) as purchases_per_artist,
		count(*) over (partition by billing_country) as total_purchases
	from tracks 
		join album using(album_id)
			join artist AR using(artist_id)
				join invoice_items using(track_id)
					join invoice I using(invoice_id)
	group by 1,2,3,4
)

select
	billing_country,
    artist_id,
    artist_name,
	purchases_per_artist / total_purchases as ratio
from purchases
group by 1,2,3
having ratio >= 0.20
```
```sql
// Revenue Contribution by Country

select
	billing_country,
    round(sum(total_price),2) AS revenue,
	sum(total_price)/(select sum(total_price) from invoice)*100 as percentage_country_rev_contribution
from invoice
group by 1
order by 2 desc;
```

## Key Insights
- Revenue Concentration:
  - Total revenue: $2,026.22
  - USA (22.4%) and Canada (13.5%) are the top revenue contributors
- Customer Behavior:
  - 59 customers with highly consistent purchase patterns (mostly 6–7 orders each)
  - Top customers contribute marginally more → low revenue concentration risk
- Genre Preferences:
  - Top genres: Rock, Latin, Metal, Alternative, Jazz
  - Rock dominates globally with 1,297 tracks
- Country-Level Personalization Opportunity:
  - Distinct top 3 genres per country identified
  - Enables localized recommendation strategies
- Artist Dominance (High-Impact Insight):
  - Only 6 countries show strong artist dominance (≥20% share)
  - Iron Maiden dominates:
    - Australia (47.4%)
    - Portugal (21.15%)
- Content & Catalog Insights:
  - Top artists by catalog depth: Iron Maiden (21 albums), Led Zeppelin (14), Deep Purple (11)
  - Majority of tracks are MPEG audio files (3034)
- Data Quality Insight:
  - 978 tracks have unknown composers, indicating metadata gaps
 
## Recommendations
- Localize recommendation engines
  - Use country-level genre preferences for personalization
- Leverage dominant artists in key markets
  - Promote high-share artists (e.g., Iron Maiden in Australia & Portugal)
- Expand high-performing genres
  - Prioritize acquisition of Rock, Latin, and Metal content
- Improve metadata quality
  - Address missing composer data to enhance recommendation accuracy
- Target top revenue markets
  - Focus marketing and promotions on USA and Canada
 
## Outcome
Delivered a customer and content analytics framework that:

- ✅ Identifies revenue drivers and engagement patterns
- ✅ Enables data-driven recommendation and acquisition strategies
- ✅ Supports geographic expansion and personalization

## Next Steps
- Build recommendation engine prototypes
- Develop dashboards for real-time engagement tracking
- Implement user segmentation and churn analysis
