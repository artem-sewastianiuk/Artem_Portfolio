USE PortfolioProject

/* Permanently add leading zeros to select values in TransactionID column [dbo].[MainData] table to be able to join other tables using
	TransactionID field */

Update [dbo].[MainData]
Set TransactionID = FORMAT (CAST (TransactionID AS NUMERIC), '000')

Update [dbo].[MainData]
Set TransactionDate = CONVERT(Date, TransactionDate)

/* Create a query which returns date of transaction, amount of transaction and the status. Check if there are any pending transactions
	for the amount of more than 4M) */

SELECT Main.[TransactionDate], Main.[Amount], Ad.[Status]
	   , CASE WHEN Ad.[Status] = 'Pending' AND Main.[Amount] >= 4000000 THEN 'Yes'
		 ELSE 'No'
		 END AS 'Check'										
FROM [dbo].[MainData] Main
JOIN [dbo].[AdditionalData] Ad
	ON Main.TransactionID = Ad.TRansactionID
WHERE (CASE WHEN Ad.[Status] = 'Pending' AND Main.[Amount] >= 4000000 THEN 'Yes'
		   ELSE 'No'
		   END) = 'Yes'

/* Sort transactions by below categories 
   Category A '2019 at EMEA'
   Category B '2019 at North America'
   Category C 'Software over 7M'
   Category D 'R&D Expense over 7M'
   Category E 'Pending in 2021'
	*/

SELECT Main.TransactionID, Amount
	   , CASE WHEN CAST (Main.TransactionDate AS DateTime) BETWEEN '2019-01-01' AND '2019-12-31' THEN CASE WHEN Main.Region = 'EMEA' THEN 'Category A'
																						WHEN Main.Region = 'North America' THEN 'Category B'
																						ELSE 'N/A' END 
			  WHEN Main.Amount >= 7000000 THEN CASE WHEN Main.BusinessUnit = 'Software' THEN 'Category C'
													WHEN Main.BusinessUnit = 'Advertising' THEN 'Category D'
													ELSE 'N/A' END
			  WHEN Ad.Status = 'Requested' AND CAST (Main.TransactionDate AS DateTime) BETWEEN '2021-01-01' AND '2021-12-31' THEN 'Category E'
			  ELSE 'N/A'
		 END AS 'Category'										
FROM [dbo].[MainData] Main
JOIN [dbo].[AdditionalData] Ad
	ON Main.TransactionID = Ad.TransactionID
GROUP BY Main.TransactionID, Amount
	   , CASE WHEN CAST (Main.TransactionDate AS DateTime) BETWEEN '2019-01-01' AND '2019-12-31' THEN CASE WHEN Main.Region = 'EMEA' THEN 'Category A'
																						                   WHEN Main.Region = 'North America' THEN 'Category B'
																						                   ELSE 'N/A' END 
			  WHEN Main.Amount >= 7000000 THEN CASE WHEN Main.BusinessUnit = 'Software' THEN 'Category C'
													WHEN Main.BusinessUnit = 'Advertising' THEN 'Category D'
													ELSE 'N/A' END
			  WHEN Ad.Status = 'Requested' AND CAST (Main.TransactionDate AS DateTime) BETWEEN '2021-01-01' AND '2021-12-31' THEN 'Category E'
			  ELSE 'N/A'
		 END 
ORDER BY 'Category'

-- Add additional permanent column to display amount in decimal data type

ALTER TABLE [dbo].[MainData]
ADD Amount_$ DECIMAL

UPDATE [dbo].[MainData]
SET Amount_$ = CONVERT (DECIMAL, Amount)

UPDATE [dbo].[MainData]
SET Region = CONVERT (NULL, Region)
WHERE Region = ''


-- Display the number of data that is not assigned to a Region and show it as 'N/A'

SELECT Region, ISNULL (Region, 'N/A') AS 'No Region', COUNT(ISNULL (Region, 'N/A')) AS 'Count'
FROM [dbo].[MainData]
WHERE Region IS NULL
GROUP BY Region

-- Concatenate first word or first three characters (if more than one word) of Account with Region. 

SELECT Account, Region
, ISNULL (CASE WHEN TRIM (SUBSTRING (Account, 1, CHARINDEX (' ', Account))) = '' THEN Account
	   ELSE TRIM (SUBSTRING (Account, 1, CHARINDEX (' ', Account)))
  END
  + ' ' + Region, Account) AS 'Account Code'
FROM [dbo].[MainData]

-- Check how many unique accounts we have 

SELECT DISTINCT Account, COUNT (Account) AS 'Count'
FROM [dbo].[MainData]
GROUP BY Account

-- Add column with row number by Business Unit and Account and keep it as CTE to use in future queries

WITH RowNumberCTE AS 
(
SELECT *, ROW_NUMBER () OVER (
		  PARTITION BY BusinessUnit, Account ORDER BY BusinessUnit, Account) Number			   
FROM [dbo].[MainData]
)
SELECT BusinessUnit, Account
FROM RowNumberCTE
WHERE Number = 1

-- Remove TransactionDate_Converted column as it is no longer needed for this project

ALTER TABLE [dbo].[MainData]
DROP COLUMN TransactionDate_Converted

-- Create temp table 

DROP TABLE IF EXISTS #CopyOfMainData
CREATE TABLE #CopyOfMainData
(
TransactionID INT,
TransactionDate DATE,
Account NVARCHAR (100),
BusinessUnit NVARCHAR (100),
Region NVARCHAR (100),
Amount DECIMAL
)

SELECT *
FROM #CopyOfMainData

-- Filter the data: Expense Accounts only, region is not blank, convert amount to PLN (1$ = 4.5 PLN)

SELECT TransactionID, TransactionDate, Account, Region, FORMAT (Amount_$ * 4.5, 'c', 'pl-PL') PLN, MAX (FORMAT (Amount_$ * 4.5, 'c', 'pl-PL')) PLN2
FROM [dbo].[MainData]
WHERE Account LIKE '%Expense' AND Region IS NOT NULL
GROUP BY TransactionID, TransactionDate, Account, Region, Amount_$
ORDER By PLN DESC

-- Calculate 0.5% and 0.2% commissions from each transaction

WITH CommissionCTE
AS (
SELECT Account, Amount_$, FORMAT (ROUND ((Amount_$ * 0.005), 2), 'c', 'us-US') AS '.05%'
						, FORMAT (ROUND ((Amount_$ * 0.002), 2), 'c', 'us-US') AS '.02%'
FROM [dbo].[MainData]
)
SELECT * 
FROM CommissionCTE

-- Create rolling total of amount by business unit, region and transaction date

SELECT TransactionDate, BusinessUnit, Region, Amount_$
	  , SUM (Amount_$) OVER (PARTITION BY BusinessUnit ORDER BY BusinessUnit, Region, TransactionDate) AS RunningTotal
FROM [dbo].[MainData]
WHERE Region IS NOT NULL
ORDER BY 1,2,3




select *
from [dbo].[MainData]


select *
from [dbo].[AdditionalData]
