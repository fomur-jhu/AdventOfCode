-- Run Day03_Load_and_Parse_Data.sql first
DECLARE
	@RowLength INT,
	@IsSampleData INT = 0 -- Change to 1 to see the sample result.

SELECT @RowLength = MAX(PD.BitIndex)
FROM ##ParsedData AS PD
WHERE PD.IsSampleData = @IsSampleData

SELECT *
FROM ##ParsedData AS PD
WHERE PD.IsSampleData = @IsSampleData;

;WITH AnalyzedData AS (
	SELECT
		PD.BitIndex,
		SUM(PD.BitValue) AS SumOfTrue,
		IIF(COUNT(*) - SUM(PD.BitValue) < SUM(PD.BitValue), 1, 0) AS Gamma,
		IIF(COUNT(*) - SUM(PD.BitValue) > SUM(PD.BitValue), 1, 0) AS Epsilon,
		@RowLength - PD.BitIndex AS BitPower
	FROM ##ParsedData AS PD
	WHERE PD.IsSampleData = @IsSampleData
	GROUP BY PD.BitIndex
)
SELECT
	SUM(IIF(AD.Gamma = 1, POWER(2, AD.BitPower), 0)) AS GammaPower,
	SUM(IIF(AD.Epsilon = 1, POWER(2, AD.BitPower), 0)) AS EpsilonPower,
	SUM(IIF(AD.Gamma = 1, POWER(2, AD.BitPower), 0)) * SUM(IIF(AD.Epsilon = 1, POWER(2, AD.BitPower), 0)) AS FinalResult
FROM AnalyzedData AS AD