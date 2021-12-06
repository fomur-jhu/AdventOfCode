-- Run Day03_Load_and_Parse_Data.sql first
DECLARE
	@RowLength INT,
	@OxyGenRating INT,
	@CO2ScrubberRating INT,
	@IsSampleData INT = 0 -- Change to 1 to see the sample result.

SELECT @RowLength = MAX(PD.BitIndex)
FROM ##ParsedData AS PD
WHERE PD.IsSampleData = @IsSampleData

-- Load initial parsed data into local a table with additional columns to be used when walk through bit columns.
DROP TABLE IF EXISTS #ProcessedData
CREATE TABLE #ProcessedData (
	RowID INT,
	BitIndex INT,
	BitValue INT,
	IsOxyGenBit INT
		DEFAULT (0),
	IsCO2ScrubberBit INT
		DEFAULT (0)
)

INSERT INTO #ProcessedData (RowID, BitIndex, BitValue)
SELECT
	PD.RowID,
	PD.BitIndex,
	PD.BitValue
FROM ##ParsedData AS PD
WHERE PD.IsSampleData = @IsSampleData

------------------------------------------------- Start with OxyGenRating -------------------------------------------------
DECLARE @CurrentBitIndex INT = 1
-- For more info: https://imgflip.com/i/5wrmbp or https://web.archive.org/web/20211206011124/https://imgflip.com/i/5wrmbp
-- or, ehm, this: https://imgflip.com/i/5wrmrh or http://web.archive.org/web/20211206011437/https://imgflip.com/i/5wrmrh
WHILE (@CurrentBitIndex <= @RowLength) BEGIN
	PRINT 'NextBit:' + CAST(@CurrentBitIndex AS VARCHAR(10));
	WITH AnalyzedData AS (
		SELECT
			PD.BitIndex,
			IIF(COUNT(*) - SUM(PD.BitValue) <= SUM(PD.BitValue), 1, 0) AS IsOxyGenBit
		FROM #ProcessedData AS PD
		LEFT JOIN #ProcessedData AS LastBitSet
			ON PD.RowID = LastBitSet.RowID
				AND PD.BitIndex - 1 = LastBitSet.BitIndex
				AND LastBitSet.IsOxyGenBit = 1
		WHERE
			PD.BitIndex = @CurrentBitIndex
			AND (PD.BitIndex = 1 OR LastBitSet.RowID IS NOT NULL)
		GROUP BY PD.BitIndex
	)
	UPDATE PD
	SET PD.IsOxyGenBit = 1
	FROM #ProcessedData AS PD
	JOIN AnalyzedData AS AD
		ON PD.BitIndex = AD.BitIndex
			AND PD.BitValue = AD.IsOxyGenBit
	LEFT JOIN #ProcessedData AS LastBitSet
		ON PD.RowID = LastBitSet.RowID
			AND PD.BitIndex - 1 = LastBitSet.BitIndex
			AND LastBitSet.IsOxyGenBit = 1
	WHERE
		PD.BitIndex = @CurrentBitIndex
		AND (PD.BitIndex = 1 OR LastBitSet.RowID IS NOT NULL)
	IF (@@ROWCOUNT = 0) BEGIN
		-- If no updates, then the previous bit index was the last one.
		SET @CurrentBitIndex = @CurrentBitIndex - 1
		BREAK;
	END
	SET @CurrentBitIndex = @CurrentBitIndex + 1
END

-- If we reached until final bit index, use row length instead.
SET @CurrentBitIndex = IIF(@CurrentBitIndex > @RowLength, @RowLength, @CurrentBitIndex)
PRINT 'Last Bit Index Contains Eligible Bit:' + CAST(@CurrentBitIndex AS VARCHAR(10))

SELECT @OxyGenRating = SUM(IIF(PD.BitValue = 1, POWER(2, @RowLength - PD.BitIndex), 0))
FROM #ProcessedData AS PD
JOIN #ProcessedData AS OxyGenBitRow
	ON PD.RowID = OxyGenBitRow.RowID
		AND OxyGenBitRow.BitIndex = @CurrentBitIndex
		AND OxyGenBitRow.IsOxyGenBit = 1

--------------------------------------------- Now CO2 Scrubber Rating -------------------------------------------------
SET @CurrentBitIndex = 1

-- For more info: https://imgflip.com/i/5wrmbp or https://web.archive.org/web/20211206011124/https://imgflip.com/i/5wrmbp
-- or, ehm, this: https://imgflip.com/i/5wrmrh or http://web.archive.org/web/20211206011437/https://imgflip.com/i/5wrmrh
WHILE (@CurrentBitIndex <= @RowLength) BEGIN
	PRINT 'NextBit:' + CAST(@CurrentBitIndex AS VARCHAR(10));
	WITH AnalyzedData AS (
		SELECT
			PD.BitIndex,
			IIF(COUNT(*) - SUM(PD.BitValue) > SUM(PD.BitValue), 1, 0) AS IsCO2ScrubberBit
		FROM #ProcessedData AS PD
		LEFT JOIN #ProcessedData AS LastBitSet
			ON PD.RowID = LastBitSet.RowID
				AND PD.BitIndex - 1 = LastBitSet.BitIndex
				AND LastBitSet.IsCO2ScrubberBit = 1
		WHERE
			PD.BitIndex = @CurrentBitIndex
			AND (PD.BitIndex = 1 OR LastBitSet.RowID IS NOT NULL)
		GROUP BY PD.BitIndex
	)
	UPDATE PD
	SET PD.IsCO2ScrubberBit = 1
	FROM #ProcessedData AS PD
	JOIN AnalyzedData AS AD
		ON PD.BitIndex = AD.BitIndex
			AND PD.BitValue = AD.IsCO2ScrubberBit
	LEFT JOIN #ProcessedData AS LastBitSet
		ON PD.RowID = LastBitSet.RowID
			AND PD.BitIndex - 1 = LastBitSet.BitIndex
			AND LastBitSet.IsCO2ScrubberBit = 1
	WHERE
		PD.BitIndex = @CurrentBitIndex
		AND (PD.BitIndex = 1 OR LastBitSet.RowID IS NOT NULL)
	IF (@@ROWCOUNT = 0) BEGIN
		-- If no updates, then the previous bit index was the last one.
		SET @CurrentBitIndex = @CurrentBitIndex - 1
		BREAK;
	END
	SET @CurrentBitIndex = @CurrentBitIndex + 1
END

-- If we reached until final bit index, use row length instead.
SET @CurrentBitIndex = IIF(@CurrentBitIndex > @RowLength, @RowLength, @CurrentBitIndex)
PRINT 'Last Bit Index Contains Eligible Bit:' + CAST(@CurrentBitIndex AS VARCHAR(10))


/*
SELECT *
FROM #ProcessedData PD
WHERE PD.BitIndex = @CurrentBitIndex AND PD.IsCO2ScrubberBit = 1

SELECT
	PD.*
FROM #ProcessedData PD
JOIN #ProcessedData CO2ScrubberBitRow
	ON PD.RowID = CO2ScrubberBitRow.RowID
	AND CO2ScrubberBitRow.BitIndex = @CurrentBitIndex
	AND CO2ScrubberBitRow.IsCO2ScrubberBit = 1
ORDER BY PD.BitIndex
*/

SELECT @CO2ScrubberRating = SUM(IIF(PD.BitValue = 1, POWER(2, @RowLength - PD.BitIndex), 0))
FROM #ProcessedData AS PD
JOIN #ProcessedData AS CO2ScrubberBitRow
	ON PD.RowID = CO2ScrubberBitRow.RowID
		AND CO2ScrubberBitRow.BitIndex = @CurrentBitIndex
		AND CO2ScrubberBitRow.IsCO2ScrubberBit = 1

----------------------------------------- Final Overview ------------------------------------------
SELECT *
FROM #ProcessedData AS PD
WHERE PD.IsOxyGenBit = 1
ORDER BY
	PD.BitIndex,
	PD.RowID

SELECT *
FROM #ProcessedData AS PD
WHERE PD.IsCO2ScrubberBit = 1
ORDER BY
	PD.BitIndex,
	PD.RowID

SELECT
	@OxyGenRating AS OxyGenRating,
	@CO2ScrubberRating AS CO2ScrubberRating,
	@OxyGenRating * @CO2ScrubberRating AS FinalResult