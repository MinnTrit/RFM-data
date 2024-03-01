-- Calculate the maximum and minimum values of Monetary, Frequency, and Recency across all customers
WITH MinMax as(
		SELECT 
			MAX(Monetary) as MaxMonetary,
	        MIN(Monetary) as MinMonetary,
	        MAX(Frequency) as MaxFrequency,
	        MIN(Frequency) as MinFrequency,
	        MAX(Recency) as MaxRecency,
	        MIN(Recency) as MinRecency
		FROM(
		-- Calculate the sum of GMV (monetary), count of purchases (frequency), and recency for each customer
	    SELECT 
			CustomerID,
			SUM(GMV) as Monetary, 
			COUNT(Purchase_date) as Frequency,
			DATEDIFF('2022-09-01', MAX(Purchase_date)) as Recency
		FROM Customer_transaction
		GROUP BY CustomerID) as Source
	),
	-- Calculate Monetary, Frequency, and Recency metrics for each customer
	MFR as(
		SELECT 
			CustomerID,
			SUM(GMV) as Monetary, 
			COUNT(distinct(Purchase_date)) as Frequency,
			DATEDIFF('2022-09-01', MAX(Purchase_date)) as Recency
		FROM Customer_transaction 
		GROUP BY CustomerID
	)
	select
		CustomerID,
		Recency,
	    Frequency,
	    Monetary,
	    CONCAT(
	    	CASE 
	        WHEN (Recency >= MinRecency AND Recency <= MaxRecency * 0.25) THEN 4
			WHEN (Recency >= MaxRecency * 0.25 AND Recency < MaxRecency * 0.5) THEN 3
			WHEN (Recency >= MaxRecency * 0.5 AND Recency < MaxRecency * 0.75) THEN 2
			WHEN (Recency >= MaxRecency * 0.75 AND Recency <= MaxRecency) THEN 1
	        END,
	        CASE 
		    When (Frequency >= Minfrequency and Frequency < Maxfrequency * 0.25) THEN 1
			When (Frequency >= Maxfrequency * 0.25 and Frequency < Maxfrequency * 0.5) THEN 2
			When (Frequency >= Maxfrequency * 0.5 and Frequency < Maxfrequency * 0.75)THEN 3
			When (Frequency >= Maxfrequency * 0.75 and Frequency <= Maxfrequency) THEN 4
			End,
	        CASE 
			WHEN (Monetary >= Minmonetary and Monetary < Maxmonetary*0.25) THEN 1
			WHEN (Monetary >= Maxmonetary*0.25 and Monetary < Maxmonetary*0.5) THEN 2
			WHEN (Monetary >= Maxmonetary*0.5 and Monetary < Maxmonetary*0.75) THEN 3
			WHEN (Monetary >= Maxmonetary*0.75 and Monetary <= Maxmonetary) then 4
	        end) as RFM
	FROM MinMax, MFR
	

-- Identify customers making purchase more than 2 times from June to August
	WITH Source AS (
    select
        CustomerID,
        Purchase_date,
    	GMV,
        MONTH(Purchase_Date) AS Purchase_Month
    FROM
        Customer_Transaction
    WHERE
        MONTH(Purchase_Date) BETWEEN 6 AND 8
    GROUP BY
        CustomerID, MONTH(Purchase_Date)
)
SELECT
    CustomerID
FROM
    Source
GROUP BY
    CustomerID
HAVING
    COUNT(DISTINCT Purchase_Month) >= 2;
   



