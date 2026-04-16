--- TOTAL_SALES 
SELECT  CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES FROM ORDERS
--------------------------------------------------------------------------------------------
---TOTAL_QUANTITY 
SELECT SUM(Quantity) as TOTAL_QUANTITY  from ORDERS
--------------------------------------------------------------------------------------------

---TOTAL_SALES_BY_Category
SELECT  Category,
		CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES_BY_Category
FROM ORDERS 
GROUP BY Category
ORDER BY SUM(Sales) DESC
--------------------------------------------------------------------------------------------

---- TOTAL_SALES_BY_PRODUCT_Name
SELECT  [Product Name],
		CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES_BY_PRODUCT_Name
FROM ORDERS 
GROUP BY [Product Name]
ORDER BY SUM(Sales) DESC

--------------------------------------------------------------------------------------------

---- TOTAL_SALES_BY_SUBCategory 
SELECT  [Sub-Category],
		CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES_BY_SUBCategory
FROM ORDERS 
GROUP BY [Sub-Category]
ORDER BY SUM(Sales) DESC

-------------------------------------------------------------------------------------------

----TOTAL_SALES_BY_Segment

SELECT  Segment,
		CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES_BY_Segment
FROM ORDERS 
GROUP BY Segment
ORDER BY SUM(Sales) DESC
-------------------------------------------------------------------------------------------

----TOTAL_SALES_BY_Country/Region
SELECT  [Country/Region],
		CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES_BY_REGION
FROM ORDERS 
GROUP BY[Country/Region]
ORDER BY SUM(Sales) DESC
-------------------------------------------------------------------------------------------
----TOTAL_SALES_BY_Country/Region_category_[Sub-Category]

SELECT  [Country/Region],category,[Sub-Category],
		CAST(ROUND (SUM(Sales),0) AS decimal(10,0) ) as TOTAL_SALES_BY_REGION
FROM ORDERS 
GROUP BY[Country/Region],category,[Sub-Category]
ORDER BY SUM(Sales) DESC

-------------------------------------------------------------------------------------------
---PROFIT 
select profit from ORDERS order by profit

-------------------------------------------------------------------------------------------

---PROFIT Margin
select sum(profit)/sum(Sales) AS PROFIT_Margin,Category from ORDERS group by Category

-------------------------------------------------------------------------------------------
---DISCOUNT_BY_PROFIT
select Discount,profit from ORDERS
order by profit 
-------------------------------------------------------------------------------------------

SELECT DISTINCT 
   [Sub-Category],
    Discount,
    profit
FROM ORDERS
order by profit ;
-------------------------------------------------------------------------------------------
--- MOVING AVG

WITH Daily_Sales AS (
    SELECT 
        CAST([Order Date] AS DATE) AS Order_Date,
        SUM(Sales) AS Total_Sales
    FROM ORDERS
    GROUP BY CAST([Order Date] AS DATE)
),

Moving_Avg AS (
    SELECT 
        Order_Date,
        Total_Sales,

        AVG(Total_Sales) OVER (
            ORDER BY Order_Date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Moving_Avg_Sales
    FROM Daily_Sales
)

SELECT 
    Order_Date,
    Total_Sales,
    Moving_Avg_Sales,

    CASE 
        WHEN Total_Sales > Moving_Avg_Sales THEN 'good'
        ELSE 'bad'
    END AS status

FROM Moving_Avg
ORDER BY Order_Date;

---------------------------------------------------------------------------
--- هامش الربح حسب الفئة (%)
SELECT Category,
       CAST(ROUND(SUM(Sales), 0) AS DECIMAL(10,0)) AS Total_Sales,
       CAST(ROUND(SUM(Profit), 0) AS DECIMAL(10,0)) AS Total_Profit,
       ROUND((SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100, 2) AS Profit_Margin_Percent
FROM ORDERS
GROUP BY Category
ORDER BY Profit_Margin_Percent DESC;

--- أكثر المنتجات خسارة (Loss Makers) - بيعت كثيراً لكن بصافي ربح سالب
SELECT TOP 20 
    [Product Name],
    Category,
    [Sub-Category],
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    AVG(Discount) AS Avg_Discount,
    ROUND((SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100, 2) AS Profit_Margin_Percent
FROM ORDERS
GROUP BY [Product Name], Category, [Sub-Category]
HAVING SUM(Profit) < 0
ORDER BY Total_Sales DESC;

--- تأثير الخصم على الربح حسب الفئة (تحليل الحساسية)
SELECT Category,
       CASE 
           WHEN Discount = 0 THEN '0%'
           WHEN Discount <= 0.2 THEN '1-20%'
           WHEN Discount <= 0.5 THEN '21-50%'
           ELSE '>50%'
       END AS Discount_Bracket,
       COUNT([order ID]) AS Number_Of_Orders,
       AVG(Profit) AS Avg_Profit_Per_Order,
       SUM(Profit) AS Total_Profit
FROM ORDERS
GROUP BY Category,
         CASE 
             WHEN Discount = 0 THEN '0%'
             WHEN Discount <= 0.2 THEN '1-20%'
             WHEN Discount <= 0.5 THEN '21-50%'
             ELSE '>50%'
         END
ORDER BY Category, Discount_Bracket;

-- =====================================================

-- =====================================================
-- 5. تحليلات زمن الشحن والكفاءة التشغيلية
-- =====================================================
--- متوسط أيام الشحن حسب وضع الشحن
SELECT [SHIP Mode],
       AVG(DATEDIFF(day, [order Date], [SHIP Date])) AS Avg_Shipping_Days,
       COUNT([order ID]) AS Total_Orders,
       AVG(Profit) AS Avg_Profit_Per_Order
FROM ORDERS
GROUP BY [SHIP Mode]
ORDER BY Avg_Shipping_Days;



--- تأثير تأخر الشحن على الخصم (هل التأخير يزيد الخصم؟)
SELECT 
    CASE 
        WHEN DATEDIFF(day, [order Date], [SHIP Date]) <= 2 THEN '0-2 Days'
        WHEN DATEDIFF(day, [order Date], [SHIP Date]) <= 5 THEN '3-5 Days'
        ELSE '>5 Days'
    END AS Shipping_Duration,
    AVG(Discount) AS Avg_Discount,
    SUM(Profit) AS Total_Profit,
    COUNT([order Date]) AS Number_Of_Orders
FROM ORDERS
GROUP BY 
    CASE 
        WHEN DATEDIFF(day, [order Date], [SHIP Date]) <= 2 THEN '0-2 Days'
        WHEN DATEDIFF(day, [order Date], [SHIP Date]) <= 5 THEN '3-5 Days'
        ELSE '>5 Days'
    END
ORDER BY Shipping_Duration;

-- =====================================================

-- =====================================================
-- 7. تحليل السلاسل الزمنية (المتوسط المتحرك)
-- =====================================================
WITH Daily_Sales AS (
    SELECT 
        CAST([order Date] AS DATE) AS Order_Date,
        SUM(Sales) AS Total_Sales
    FROM ORDERS
    GROUP BY CAST([order Date] AS DATE)
),
Moving_Avg AS (
    SELECT 
        Order_Date,
        Total_Sales,
        AVG(Total_Sales) OVER (
            ORDER BY Order_Date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW  -- متوسط متحرك لـ 7 أيام
        ) AS Moving_Avg_Sales_7d
    FROM Daily_Sales
)
SELECT 
    Order_Date,
    Total_Sales,
    Moving_Avg_Sales_7d,
    CASE 
        WHEN Total_Sales > Moving_Avg_Sales_7d THEN 'Above Average'
        WHEN Total_Sales < Moving_Avg_Sales_7d THEN 'Below Average'
        ELSE 'Average'
    END AS Performance_vs_Week
FROM Moving_Avg
ORDER BY Order_Date;

-- =====================================================
-- 8. تحليل سلة المشتريات (Basket Analysis) - منتجات تباع معاً
-- =====================================================
--- أكثر أزواج الفئات الفرعية شيوعاً في نفس الطلب
WITH Order_SubCategories AS (
    SELECT DISTINCT [order ID], [Sub-Category]
    FROM ORDERS
)
SELECT 
    a.[Sub-Category] AS Product_A,
    b.[Sub-Category] AS Product_B,
    COUNT(*) AS Times_Bought_Together
FROM Order_SubCategories a
JOIN Order_SubCategories b 
    ON a.[order ID] = b.[order ID] 
    AND a.[Sub-Category] < b.[Sub-Category]  -- تجنب التكرار والعكس
GROUP BY a.[Sub-Category], b.[Sub-Category]
ORDER BY Times_Bought_Together DESC;

-- ===================================================== 

----تحليل مساهمة كل منتج في إجمالي المبيعات (Pareto Analysis)
WITH Product_Sales AS (
    SELECT 
        [Product Name],
        SUM(Sales) AS Total_Sales
    FROM ORDERS
    GROUP BY [Product Name]
),
Cumulative AS (
    SELECT 
        [Product Name],
        Total_Sales,
        SUM(Total_Sales) OVER (ORDER BY Total_Sales DESC) AS Running_Total,
        SUM(Total_Sales) OVER () AS Grand_Total
    FROM Product_Sales
)
SELECT 
    [Product Name],
    Total_Sales,
    FORMAT(Total_Sales / Grand_Total, 'P2') AS Sales_Percentage,
    FORMAT(Running_Total / Grand_Total, 'P2') AS Cumulative_Percentage,
    CASE 
        WHEN Running_Total / Grand_Total <= 0.80 THEN 'Class A (Top 80%)'
        WHEN Running_Total / Grand_Total <= 0.95 THEN 'Class B (Next 15%)'
        ELSE 'Class C (Bottom 5%)'
    END AS Pareto_Class
FROM Cumulative
ORDER BY Total_Sales DESC;

---------------------------------------------------------------------
---======تحليل معدل النمو الشهري (Month-over-Month Growth)

WITH Monthly AS (
    SELECT 
        YEAR([order Date]) AS Order_Year,
        MONTH([order Date]) AS Order_Month,
        SUM(Sales) AS Monthly_Sales
    FROM ORDERS
    GROUP BY YEAR([order Date]), MONTH([order Date])
),
Growth AS (
    SELECT 
        Order_Year,
        Order_Month,
        Monthly_Sales,
        LAG(Monthly_Sales) OVER (ORDER BY Order_Year, Order_Month) AS Prev_Month_Sales,
        (Monthly_Sales - LAG(Monthly_Sales) OVER (ORDER BY Order_Year, Order_Month)) 
            / NULLIF(LAG(Monthly_Sales) OVER (ORDER BY Order_Year, Order_Month), 0) * 100 AS MoM_Growth_Percent
    FROM Monthly
)
SELECT 
    Order_Year,
    Order_Month,
    Monthly_Sales,
    Prev_Month_Sales,
    FORMAT(MoM_Growth_Percent / 100, 'P2') AS MoM_Growth
FROM Growth
ORDER BY Order_Year, Order_Month;
------------------------------------

--تحليل "القيمة الدائمة للعميل" (Customer Lifetime Value - CLV)

WITH Customer_Stats AS (
    SELECT 
        [Customer ID],
        DATEDIFF(DAY, MIN([order Date]), MAX([order Date])) AS Customer_Lifetime_Days,
        COUNT(DISTINCT [order Date]) AS Order_Count,
        SUM(Sales) AS Total_Revenue,
        SUM(Profit) AS Total_Profit
    FROM ORDERS
    GROUP BY [Customer ID]
)
SELECT 
    [Customer ID],
    Customer_Lifetime_Days,
    Order_Count,
    Total_Revenue,
    Total_Profit,
    -- متوسط قيمة الطلب
    Total_Revenue / NULLIF(Order_Count, 0) AS Avg_Order_Value,
    -- معدل الشراء الشهري
    Order_Count * 30.0 / NULLIF(Customer_Lifetime_Days, 0) AS Monthly_Purchase_Frequency,
    -- القيمة المتوقعة للعميل خلال 12 شهر قادم
    (Total_Revenue / NULLIF(Customer_Lifetime_Days, 0)) * 365 AS Predicted_Annual_Value
FROM Customer_Stats
WHERE Customer_Lifetime_Days > 0
ORDER BY Predicted_Annual_Value DESC;

---=====================================

