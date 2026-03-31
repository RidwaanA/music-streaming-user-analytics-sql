/*
Project: Music Streaming User Engagement & Revenue Performance Analysis

Business Context:
Don Beats is a global music startup selling records across multiple countries.
Leadership seeks insight into customer listening preferences to guide
recommendation strategies and artist acquisition decisions.

Key Objectives:
- Analyse purchase data to identify top genres by country
- Detect country-specific artist preferences
- Provide insights to support targeted recommendations and contracting decisions

This analysis supports recommendation engine optimization and expansion strategy
*/

/* =======================================================================
SECTION-01: DATA FAMILIARIZATION & STRUCTURE VALIDATION
Objective: Understand schema, table relationships, and data completeness
=======================================================================-*/

-- [1] Inspecting core transactional & dimension tables
select * from album
limit 10;

select * from artist
limit 10;

select * from customers
limit 10;

select * from genre
limit 10;

select * from invoice
limit 10;

select * from invoice_items
limit 10;

select * from mediatype
limit 10;

select * from playlist
limit 10;

select * from playlisttrack
limit 10;

select * from tracks
limit 10;

/* =============================================================================
SECTION 02 — SUPPLY CATALOG ANALYSIS
Objective: Understand product depth, artist coverage, and content distribution
============================================================================= */

-- [2] Albums per Artist (Catalog Depth)
select
	AR.artist_id,
    AR.artist_name,
    count(album_id) as num_of_albums    
from artist AR
	join album using(artist_id)
group by 1,2
order by 3 desc;

-- [3] Total Playlists
select
	count(playlist_id) as num_of_playlists
from playlist;

-- [4] Tracks per Playlist
select
	P.playlist_id,
    P.playlist_name,
    count(track_id) as num_of_tracks
from playlisttrack 
	join playlist P using(playlist_id)
group by 1,2
order by 3 desc;
    
-- [5] Catalog Breadth Summary
select
	count(distinct track_id) as num_of_tracks,
    count(distinct genre_id) as num_of_genres,
    count(distinct album_id) as num_of_albums,
	count(distinct media_type_id) as num_of_media_type,
    count(distinct composer) as num_of_composers
from tracks;

/* =================================================================
SECTION 03 — CUSTOMER BASE & GEOGRAPHIC DISTRIBUTION
Objective: Understand market penetration and country-level demand
================================================================= */

-- [6] Total Customers
select
	count(customer_id) as number_of_customers
from customers;

-- [7] Customers by Country
select
	customer_country,
	count(customer_id) as number_of_customers
from customers
group by 1
order by 2 desc;

/* =============================================================================
SECTION 04 — REVENUE PERFORMANCE ANALYSIS
Objective: Measure revenue scale and country contribution
============================================================================= */

-- [8] Total Revenue
select
	round(sum(total_price), 2) as total_revenue
from invoice;

-- [9] Percent Revenue Contribution by Country
select
	billing_country,
	sum(total_price)/(select sum(total_price) from invoice)*100 as percentage_country_rev_contribution
from invoice
group by 1
order by 2 desc;

/* ======================================================================
SECTION 05 — HIGH-VALUE CUSTOMER IDENTIFICATION
Objective: Identify top customers by revenue and transaction frequency
====================================================================== */

-- [10] Top Customers by Revenue
select
	customer_id,
    concat(C.first_name, ' ', C.last_name) as full_name,
    round(sum(total_price), 2) as total_spent
from customers C
	join invoice using(customer_id)
group by 1,2
order by 3 desc;

-- [11] Top Customers by Orders
select
	customer_id,
    concat(C.first_name, ' ', C.last_name) as full_name,
    count(invoice_id) as total_orders
from customers C
	join invoice using(customer_id)
group by 1,2
order by 3 desc;

/* ===============================================================================
SECTION 06 — PRODUCT & PRICING ANALYSIS
Objective: Understand pricing tiers, media performance, and file characteristics
=============================================================================== */
    
-- [12] Pricing Distribution & Average File Size
select
	unit_price,
    avg(bytes) as average_size_byte
from tracks
group by 1
order by 1;

-- [13] Average Track Size (MB)
select
	ROUND(avg(bytes) / 1048576, 2) as 'average_size(MB)'
from tracks;

-- [14] Average Price by Media Type
select
	M.media_type_id,
    M.media_type_code,    
	avg(unit_price) as average_price
from mediatype M
	join tracks using(media_type_id)
group by 1,2
order by 3 desc;

/* ========================================================================
SECTION 07 — CONTENT DISTRIBUTION INSIGHTS
Objective: Identify concentration across albums, genres, and media types
======================================================================== */

-- [15] Tracks per Album
select
	AL.album_id,
    AL.title_name,
    count(track_id) as num_of_tracks
from album AL
	join tracks using(album_id)
group by 1,2
order by 3 desc;

-- [16] Tracks per Genre
select
	G.genre_id,
    G.genre_name,
    count(track_id) as num_of_tracks
from genre G
	join tracks using(genre_id)
group by 1,2
order by 3 desc;
    
-- [17] Tracks per Media Type
select
	M.media_type_id,
    M.media_type_code,
    count(track_id) as num_of_tracks
from mediatype M
	join tracks using(media_type_id)
group by 1,2
order by 3 desc;

-- [19] Tracks per Composer
select
	composer,
    count(track_id) as num_of_tracks
from tracks
group by 1
order by 2 desc;

-- [20] Tracks per Unknown Composer
select
	count(track_id) as num_of_tracks
from tracks 
where composer = '';

/* ====================================================================
SECTION 08 — CUSTOMER PURCHASE BEHAVIOR & RECOMMENDATION INSIGHTS
Objective: Identify demand patterns for recommendation optimization
=================================================================== */

-- [21] Top 5 Purchased Genres
select
    G.genre_id,
    G.genre_name,
    count(track_id) as num_of_tracks
from invoice_items
	join tracks using(track_id)
		join genre G using(genre_id)
group by 1,2
order by 3 desc
limit 5;

-- [22] Top 5 Preferred Composers
select
	composer,
    count(track_id) as num_of_tracks
from invoice_items
	join tracks using(track_id)
where composer != ''
group by 1
order by 2 desc
limit 5;

-- [23] Top 3 Genres (by Orders) per Country
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

/* =============================================================================
SECTION 09 — COUNTRY-SPECIFIC ARTIST DOMINANCE (20%+ MARKET SHARE RULE)
Objective: Identify artists with strong localized market penetration
============================================================================= */

-- [24] 
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
order by ratio desc;

/* ==========================================================
SECTION 10 — EXECUTIVE SUMMARY OUTPUT (BOARD-READY METRICS)
Objective: Provide concise KPIs for leadership reporting
========================================================== */

-- [25] Total Revenue & Customer Count
select
    (select count(*) from customers) as total_customers,
    (select sum(total_price) from invoice) as total_revenue;

-- [26] Top Revenue Country
select
    billing_country,
    round(sum(total_price), 2) AS total_country_revenue
from invoice
group by 1
order by 2 desc
limit 1;

-- [27] Most Purchased Genre Overall
select
    G.genre_name,
    count(*) as total_purchases
from invoice_items
	join tracks using(track_id)
		join genre G using(genre_id)
group by 1
order by 2 desc
limit 1;

-- [28] Highest Spending Customer
select
    concat(first_name, ' ', last_name) as top_customer,
    sum(total_price) as total_spent
from customers
	join invoice using(customer_id)
group by 1
order by 2 desc
limit 1;
 