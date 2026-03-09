  -- SWIGGY SALES ANALYSIS

CREATE TABLE swiggy_data (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    state           VARCHAR(100),
    city            VARCHAR(100),
    order_date      DATE,
    restaurant_name VARCHAR(200),
    location        VARCHAR(200),
    category        VARCHAR(100),
    dish_name       VARCHAR(200),
    price_inr       DECIMAL(10, 2),
    rating          DECIMAL(3, 1),
    rating_count    INT
);

-- 2.1 Total Sales Revenue
SELECT ROUND(SUM(price_inr), 2) AS total_sales_inr
FROM swiggy_data;

-- 2.2 Average Rating
SELECT ROUND(AVG(rating), 1) AS average_rating
FROM swiggy_data;

-- 2.3 Average Order Value
SELECT ROUND(AVG(price_inr), 2) AS avg_order_value_inr
FROM swiggy_data;

-- 2.4 Total Rating Count
SELECT SUM(rating_count) AS total_rating_count
FROM swiggy_data;

-- 2.5 Total Number of Orders
SELECT COUNT(*) AS total_orders
FROM swiggy_data;

-- 2.6 Total Unique Restaurants
SELECT COUNT(DISTINCT restaurant_name) AS total_restaurants
FROM swiggy_data;

-- 2.7 Total Unique Cities
SELECT COUNT(DISTINCT city) AS total_cities
FROM swiggy_data;

-- 2.8 All KPIs in One Query
SELECT
    COUNT(*)                        AS total_orders,
    ROUND(SUM(price_inr), 2)        AS total_sales_inr,
    ROUND(AVG(price_inr), 2)        AS avg_order_value_inr,
    ROUND(AVG(rating), 1)           AS average_rating,
    SUM(rating_count)               AS total_rating_count,
    COUNT(DISTINCT restaurant_name) AS total_restaurants,
    COUNT(DISTINCT city)            AS total_cities
FROM swiggy_data;

-- SECTION 3: TIME-BASED ANALYSIS

-- 3.1 Monthly Sales Trend

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS year_month,
    ROUND(SUM(price_inr), 2)         AS monthly_revenue,
    COUNT(*)                          AS total_orders,
    ROUND(AVG(price_inr), 2)         AS avg_order_value
FROM swiggy_data
GROUP BY year_month
ORDER BY year_month;

-- 3.2 Daily Sales Trend (Monday to Sunday)
SELECT
    DAYNAME(order_date)      AS day_name,
    ROUND(SUM(price_inr), 2) AS daily_revenue,
    COUNT(*)                  AS total_orders
FROM swiggy_data
GROUP BY day_name
ORDER BY FIELD(day_name,
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- 3.3 Quarterly Performance Summary
SELECT
    CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS quarter,
    ROUND(SUM(price_inr), 0)                             AS total_sales_inr,
    ROUND(AVG(rating), 2)                                AS avg_rating,
    COUNT(*)                                             AS total_orders,
    ROUND(AVG(price_inr), 2)                             AS avg_order_value
FROM swiggy_data
GROUP BY quarter
ORDER BY quarter;

-- 3.4 Yearly Revenue Summary
SELECT
    YEAR(order_date)         AS year,
    ROUND(SUM(price_inr), 2) AS total_revenue,
    COUNT(*)                  AS total_orders,
    ROUND(AVG(price_inr), 2) AS avg_order_value,
    ROUND(AVG(rating), 2)    AS avg_rating
FROM swiggy_data
GROUP BY year
ORDER BY year;

-- 3.5 Peak Hour / Day Analysis (orders per weekday vs weekend)
SELECT
    CASE
        WHEN DAYOFWEEK(order_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    ROUND(SUM(price_inr), 2) AS total_revenue,
    COUNT(*)                  AS total_orders,
    ROUND(AVG(price_inr), 2) AS avg_order_value
FROM swiggy_data
GROUP BY day_type;

-- SECTION 4: LOCATION-BASED ANALYSIS

-- 4.1 Revenue by State
SELECT
    state,
    ROUND(SUM(price_inr), 2)        AS total_revenue,
    COUNT(*)                          AS total_orders,
    COUNT(DISTINCT restaurant_name)  AS total_restaurants,
    ROUND(AVG(price_inr), 2)         AS avg_order_value,
    ROUND(AVG(rating), 2)            AS avg_rating
FROM swiggy_data
GROUP BY state
ORDER BY total_revenue DESC;

-- 4.2 Top 10 Cities by Revenue
SELECT
    city,
    state,
    ROUND(SUM(price_inr), 2)        AS total_revenue,
    COUNT(*)                          AS total_orders,
    COUNT(DISTINCT restaurant_name)  AS total_restaurants,
    ROUND(AVG(price_inr), 2)         AS avg_order_value
FROM swiggy_data
GROUP BY city, state
ORDER BY total_revenue DESC
LIMIT 10;

-- 4.3 City Rank Within State (Window Function)
SELECT
    state,
    city,
    ROUND(SUM(price_inr), 2)                                        AS total_revenue,
    COUNT(*)                                                          AS total_orders,
    RANK() OVER (PARTITION BY state ORDER BY SUM(price_inr) DESC)   AS city_rank_in_state
FROM swiggy_data
GROUP BY state, city
ORDER BY state, city_rank_in_state;

-- 4.4 Top 5 Locations Within Each City
WITH location_revenue AS (
    SELECT
        city,
        location,
        ROUND(SUM(price_inr), 2)                                         AS total_revenue,
        COUNT(*)                                                           AS total_orders,
        RANK() OVER (PARTITION BY city ORDER BY SUM(price_inr) DESC)     AS loc_rank
    FROM swiggy_data
    GROUP BY city, location
)
SELECT * FROM location_revenue
WHERE loc_rank <= 5
ORDER BY city, loc_rank;



-- SECTION 5: RESTAURANT ANALYSIS

-- 5.1 Top 10 Restaurants by Revenue
SELECT
    restaurant_name,
    city,
    ROUND(SUM(price_inr), 2) AS total_revenue,
    COUNT(*)                  AS total_orders,
    ROUND(AVG(rating), 2)    AS avg_rating,
    SUM(rating_count)         AS total_reviews
FROM swiggy_data
GROUP BY restaurant_name, city
ORDER BY total_revenue DESC
LIMIT 10;

-- 5.2 Top 10 Restaurants by Order Count
SELECT
    restaurant_name,
    city,
    COUNT(*)                  AS total_orders,
    ROUND(SUM(price_inr), 2) AS total_revenue,
    ROUND(AVG(rating), 2)    AS avg_rating
FROM swiggy_data
GROUP BY restaurant_name, city
ORDER BY total_orders DESC
LIMIT 10;

-- 5.3 Highest Rated Restaurants (min 10 orders)
SELECT
    restaurant_name,
    city,
    ROUND(AVG(rating), 2)    AS avg_rating,
    SUM(rating_count)         AS total_reviews,
    COUNT(*)                  AS total_orders,
    ROUND(SUM(price_inr), 2) AS total_revenue
FROM swiggy_data
GROUP BY restaurant_name, city
HAVING total_orders >= 10
ORDER BY avg_rating DESC, total_reviews DESC
LIMIT 20;

-- 5.4 Restaurant Performance Tier (Window Function)
SELECT
    restaurant_name,
    city,
    ROUND(SUM(price_inr), 2)     AS total_revenue,
    COUNT(*)                      AS total_orders,
    ROUND(AVG(rating), 2)        AS avg_rating,
    NTILE(4) OVER (ORDER BY SUM(price_inr) DESC) AS revenue_quartile
FROM swiggy_data
GROUP BY restaurant_name, city
ORDER BY total_revenue DESC;

-- SECTION 6: FOOD / DISH ANALYSIS

-- 6.1 Top 10 Best-Selling Dishes
SELECT
    dish_name,
    category,
    COUNT(*)                  AS times_ordered,
    ROUND(SUM(price_inr), 2) AS total_revenue,
    ROUND(AVG(price_inr), 2) AS avg_price,
    ROUND(AVG(rating), 2)    AS avg_rating
FROM swiggy_data
GROUP BY dish_name, category
ORDER BY times_ordered DESC
LIMIT 10;

-- 6.2 Revenue by Category
SELECT
    category,
    ROUND(SUM(price_inr), 2)  AS total_revenue,
    COUNT(*)                   AS total_orders,
    ROUND(AVG(price_inr), 2)  AS avg_price,
    ROUND(AVG(rating), 2)     AS avg_rating
FROM swiggy_data
GROUP BY category
ORDER BY total_revenue DESC;

-- 6.3 Veg vs Non-Veg Revenue Split
SELECT
    CASE
        WHEN LOWER(dish_name) REGEXP 'chicken|mutton|fish|egg|prawn|beef|meat|lamb|pork'
        THEN 'Non-Veg'
        ELSE 'Veg'
    END AS food_category,
    ROUND(SUM(price_inr), 2)  AS total_revenue,
    COUNT(*)                   AS total_orders,
    ROUND(AVG(price_inr), 2)  AS avg_price,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2
    )                          AS order_percentage
FROM swiggy_data
GROUP BY food_category;

-- 6.4 Price Bucket Analysis
SELECT
    CASE
        WHEN price_inr < 100              THEN 'Under ₹100'
        WHEN price_inr BETWEEN 100 AND 299 THEN '₹100 - ₹299'
        WHEN price_inr BETWEEN 300 AND 499 THEN '₹300 - ₹499'
        WHEN price_inr BETWEEN 500 AND 999 THEN '₹500 - ₹999'
        ELSE '₹1000 and above'
    END AS price_bucket,
    COUNT(*)                   AS total_orders,
    ROUND(SUM(price_inr), 2)  AS total_revenue,
    ROUND(AVG(rating), 2)     AS avg_rating
FROM swiggy_data
GROUP BY price_bucket
ORDER BY MIN(price_inr);

-- SECTION 7: RATING ANALYSIS

-- 7.1 Rating Distribution
SELECT
    CASE
        WHEN rating >= 4.5 THEN 'Excellent (4.5-5.0)'
        WHEN rating >= 4.0 THEN 'Good (4.0-4.4)'
        WHEN rating >= 3.5 THEN 'Average (3.5-3.9)'
        WHEN rating >= 3.0 THEN 'Below Average (3.0-3.4)'
        ELSE 'Poor (Below 3.0)'
    END AS rating_category,
    COUNT(*)                   AS total_orders,
    ROUND(SUM(price_inr), 2)  AS total_revenue,
    ROUND(AVG(price_inr), 2)  AS avg_order_value
FROM swiggy_data
GROUP BY rating_category
ORDER BY MIN(rating) DESC;

-- 7.2 Cities with Highest Average Rating
SELECT
    city,
    ROUND(AVG(rating), 2)    AS avg_rating,
    COUNT(*)                  AS total_orders,
    ROUND(SUM(price_inr), 2) AS total_revenue
FROM swiggy_data
GROUP BY city
HAVING total_orders >= 100
ORDER BY avg_rating DESC
LIMIT 10;

-- 7.3 Correlation: Price vs Rating (Avg Price per Rating Bucket)
SELECT
    rating,
    COUNT(*)                  AS total_orders,
    ROUND(AVG(price_inr), 2) AS avg_price,
    ROUND(SUM(price_inr), 2) AS total_revenue
FROM swiggy_data
GROUP BY rating
ORDER BY rating DESC;

-- 9.2 View: City Performance
CREATE VIEW vw_city_performance AS
SELECT
    state,
    city,
    ROUND(SUM(price_inr), 2)        AS total_revenue,
    COUNT(*)                          AS total_orders,
    ROUND(AVG(price_inr), 2)         AS avg_order_value,
    ROUND(AVG(rating), 2)            AS avg_rating,
    COUNT(DISTINCT restaurant_name)  AS total_restaurants
FROM swiggy_data
GROUP BY state, city;


-- END OF SWIGGY SQL ANALYSIS