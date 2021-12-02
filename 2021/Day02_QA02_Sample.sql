DROP TABLE IF EXISTS #ParsedData
DROP TABLE IF EXISTS #AimAddedData
GO

CREATE TABLE #ParsedData (
	RowID INT IDENTITY PRIMARY KEY CLUSTERED,
	DirectionType VARCHAR(63) NULL,
	DirectionValue INT NULL,
	DeltaX AS (IIF(DirectionType = 'Forward', DirectionValue, 0)),
	DeltaY AS (CASE DirectionType
				   WHEN 'Up' THEN
					   DirectionValue
				   WHEN 'Down' THEN
					   -DirectionValue
				   ELSE
					   0
			   END
			  )
)

DECLARE @RawData VARCHAR(MAX) = 
'"forward 5
down 5
forward 8
up 3
down 8
forward 2"'


DECLARE @JsonArray VARCHAR(MAX) = '[' + REPLACE(@RawData, CHAR(13) + CHAR(10), '", "') + ']'

INSERT INTO #ParsedData (DirectionType, DirectionValue)
SELECT
	PARSENAME(REPLACE(j.Value, ' ', '.'), 2),
	PARSENAME(REPLACE(j.Value, ' ', '.'), 1)
FROM OPENJSON(@JsonArray) AS j


SELECT
	PD.*,
	-SUM(PD.DeltaY) OVER (ORDER BY PD.RowID ROWS UNBOUNDED PRECEDING) * PD.DeltaX AS DeltaDepth
INTO #AimAddedData
FROM #ParsedData AS PD

SELECT *
FROM #AimAddedData

SELECT
	SUM(AAD.DeltaX) AS HorizontalPosition,
	SUM(AAD.DeltaDepth) AS Depth,
	ABS(SUM(AAD.DeltaX) * SUM(AAD.DeltaDepth)) AS Result
FROM #AimAddedData AS AAD

