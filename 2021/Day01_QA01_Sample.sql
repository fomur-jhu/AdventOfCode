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
		LAG(DWI.ElementValue, 1, 0) OVER (ORDER BY DWI.CakmaOrdinal) AS PreviousValue 
	FROM DataWithIndex DWI
), MeasuredData AS
(
SELECT 
	AD.ElementValue,
	CASE
		WHEN AD.CakmaOrdinal = 1 THEN '(N/A - no previous measurement)'
		WHEN AD.ElementValue > AD.PreviousValue THEN 'Increased'
		WHEN AD.ElementValue = AD.PreviousValue THEN 'Same'
		WHEN AD.ElementValue < AD.PreviousValue THEN 'Decreased'
	END AS Measurement
	FROM AnalyzedData AD
)
SELECT *
INTO #MeasuredData
FROM MeasuredData


SELECT COUNT(*) AS IncreasedCount
FROM #MeasuredData MD
WHERE MD.Measurement = 'Increased'
