
WITH combined_cte AS (
	SELECT
	a.name AS app_store_name,
	p.name AS play_store_name,
	COALESCE(a.name, p.name) AS app_name,-- removing null name and replacing with the next one
	CASE WHEN a.name IS NULL THEN 'playstore'
		 WHEN p.name IS NULL THEN 'appstore'
		 ELSE 'bothstores'
	END AS store,
	CASE WHEN a.name IS NULL THEN 1
		 WHEN p.name IS NULL THEN 1
		 ELSE 2 
	END AS store_count,
	COALESCE(a.price,0) AS app_store_price, --removing null from price
	COALESCE(REPLACE(p.price, '$', ''):: NUMERIC,0) AS play_store_price,--removing null from price
	COALESCE(a.rating,0) AS app_store_rating, --removing null from rating
	COALESCE(p.rating,0) AS play_store_rating, --removing null from rating
	a.primary_genre AS app_genre,
	p.genres AS play_genre,
	COALESCE(a.primary_genre, p.genres) AS apps_genre,-- removing null name and replacing with the next one
	COALESCE(a.review_count:: NUMERIC,0) AS app_review,
	COALESCE(p.review_count:: NUMERIC,0)  AS play_review
	--COALESCE(a.review_count:: NUMERIC, p.review_count:: NUMERIC) AS apps_reviews
	FROM app_store_apps a
	FULL JOIN play_store_apps p
	USING (name)
	),
-------------------------------------------------------------
	--calculate higher of app or play store price
-------------------------------------------------------------
highest_price_cte AS(
SELECT 
	*,
	GREATEST(app_store_price, play_store_price) AS highest_price
FROM combined_cte
),
-------------------------------------------------------------
--multiplying highest price to 10000
-------------------------------------------------------------
purchase_price_cte AS(
SELECT 
	*,
	CASE WHEN highest_price::NUMERIC < '1' THEN 10000 
	ELSE
		ROUND(highest_price :: NUMERIC) * 10000 -- rounding the amount to the nearest dollar
		END AS purchase_price
FROM highest_price_cte
ORDER BY purchase_price DESC),
-------------------------------------------------------------
--calculating earnings and expense
-------------------------------------------------------------
earnings_cte AS (
	SELECT *,
			CASE 
				WHEN store_count = 2 THEN 10000
		 		ELSE 5000
		 	END AS earning_per_month,
			1000 AS marketing_expense_per_month
	FROM purchase_price_cte
			),
		
-----------------------------------------------------------
--calculating ratings
-------------------------------------------------------------
rating_cte AS(
	SELECT *,
		CASE WHEN store_count = 1 THEN GREATEST(app_store_rating, play_store_rating)
			ELSE 
		ROUND(ROUND(COALESCE(app_store_rating,0) + COALESCE(play_store_rating,0),0)/2,2) 
		END AS avg_ratings,
		(((ROUND(ROUND(COALESCE(app_store_rating,0) + COALESCE(play_store_rating,0),0)/2,2))*2)+1) AS lifespan_years,
		CASE WHEN store_count = 1 THEN GREATEST(app_review, play_review)
			ELSE 
		ROUND((app_review + play_review),0)/2
		END AS avg_reviews
	FROM earnings_cte
		),
		
--SELECT
--	* 
--FROM rating_cte 
---------------------------------------------------------------------------------
--calculating profit
---------------------------------------------------------------------------------
profit_cte AS(
	SELECT *,
	(((earning_per_month - marketing_expense_per_month) *12 * lifespan_years)- purchase_price) AS profit
FROM rating_cte 
	)

---------------------------------------------------------------------------------
--e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same
--$1000 per month.

--SELECT 
--	*
--FROM profit_cte

SELECT DISTINCT
	app_name,
--	store,
--	store_count,
--	highest_price,
--	purchase_price,
--	earning_per_month,
--	marketing_expense_per_month
--	apps_genre,
--	avg_ratings,
--	lifespan_years,
	profit
FROM profit_cte
WHERE app_store_name = play_store_name
ORDER BY profit DESC, app_name ASC;
