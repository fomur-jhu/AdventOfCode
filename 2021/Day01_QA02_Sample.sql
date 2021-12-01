DROP TABLE IF EXISTS #MeasuredData
GO
DECLARE @RawData NVARCHAR(MAX) =
'199
200
208
210
200
207
240
269
260
263'

DECLARE @JsonArray NVARCHAR(MAX) = '[' + REPLACE(@RawData, CHAR(13)+CHAR(10), ', ')  +']'

; WITH DataWithIndex AS 
(
	SELECT CAST(j.[key] AS INT) + 1 AS CakmaOrdinal, CAST(j.value AS INT) AS ElementValue
	FROM OPENJSON(@JsonArray) AS j
), AnalyzedData AS
(
	SELECT
		DWI.CakmaOrdinal,
		DWI.ElementValue,		
		SUM(DWI.ElementValue) OVER (
			ORDER BY DWI.CakmaOrdinal
			ROWS BETWEEN 
				CURRENT ROW
				AND 2 FOLLOWING) AS CurrentWindowSum,
		SUM(DWI.ElementValue) OVER (
			ORDER BY DWI.CakmaOrdinal
			ROWS BETWEEN 
				1 PRECEDING
				AND 1 FOLLOWING) AS PreviousWindowSum,
		LEAD(DWI.ElementValue, 2, -1) OVER (ORDER BY DWI.CakmaOrdinal) AS ThirdRowValue
	FROM DataWithIndex DWI
), MeasuredData AS
(
SELECT 
	AD.*,
	CASE
		WHEN AD.CakmaOrdinal = 1 THEN '(N/A - no previous measurement)'
		WHEN AD.ThirdRowValue = -1 THEN '(N/A - not enough measurement)'
		WHEN AD.CurrentWindowSum > AD.PreviousWindowSum THEN 'increased'
		WHEN AD.CurrentWindowSum = AD.PreviousWindowSum THEN '(no change)'
		WHEN AD.CurrentWindowSum < AD.PreviousWindowSum THEN 'decreased'
	END AS Measurement
	FROM AnalyzedData AD	
)
SELECT *
INTO #MeasuredData
FROM MeasuredData

SELECT *
FROM #MeasuredData

SELECT COUNT(*) AS IncreasedCount
FROM #MeasuredData MD
WHERE MD.Measurement = 'Increased'
