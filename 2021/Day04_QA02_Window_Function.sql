-- Run Day04_Load_and_Parse_Data.sql first
DECLARE	
	@IsSampleData INT = 0, -- Change to 1 to see the sample result.
	@LastBoardNumber INT = 0,
	@LastPickOrder INT

DROP TABLE IF EXISTS #PickedNumbers
DROP TABLE IF EXISTS #BingoBoards
DROP TABLE IF EXISTS #Bingos
CREATE TABLE #PickedNumbers(PickOrder INT PRIMARY KEY, PickedNumber INT)
CREATE TABLE #BingoBoards (BingoBoardID INT IDENTITY PRIMARY KEY, BoardNumber INT, RowID INT, ColumnIndex INT, ColumnValue INT)


INSERT INTO #PickedNumbers (PickOrder, PickedNumber)
SELECT PN.PickOrder,
	   PN.PickedNumber 
FROM ##PickedNumbers PN
WHERE PN.IsSampleData = @IsSampleData

INSERT INTO #BingoBoards (BoardNumber, RowID, ColumnIndex, ColumnValue)
SELECT BB.BoardNumber,
	   BB.RowID,
	   BB.ColumnIndex,
	   BB.ColumnValue
FROM ##BingoBoards BB
WHERE BB.IsSampleData = @IsSampleData

CREATE NONCLUSTERED INDEX idx_ByColumnValue ON #BingoBoards (ColumnValue) INCLUDE (BoardNumber, RowID, ColumnIndex)
CREATE NONCLUSTERED INDEX idx_ByBoardNumber ON #BingoBoards (BoardNumber) INCLUDE (ColumnValue)

;WITH Drawings AS
(
SELECT 
	BB.BoardNumber,
	BB.ColumnIndex,
	BB.RowID,	
	PN.PickOrder,
	IIF(DENSE_RANK() OVER (PARTITION BY BB.BoardNumber, BB.RowID ORDER BY PN.PickOrder) = 5 OR DENSE_RANK() OVER (PARTITION BY BB.BoardNumber, BB.ColumnIndex ORDER BY PN.PickOrder) = 5, 1, 0) IsBingo	
FROM #BingoBoards BB
JOIN #PickedNumbers PN
	ON BB.ColumnValue = PN.PickedNumber
GROUP BY 
	PN.PickOrder,
	BB.BoardNumber,
	BB.ColumnIndex,
	BB.RowID
)
, Bingos AS
(
	SELECT DISTINCT
    D.PickOrder, D.BoardNumber,
	DENSE_RANK() OVER (PARTITION BY D.BoardNumber ORDER BY D.PickOrder, D.BoardNumber) BoardBingoCount
	FROM Drawings D
	WHERE D.IsBingo = 1
)
SELECT TOP (1) @LastPickOrder = B.PickOrder, @LastBoardNumber = B.BoardNumber
FROM Bingos B
WHERE B.BoardBingoCount = 1
ORDER BY B.PickOrder DESC, B.BoardNumber

SELECT @LastPickOrder AS LastPickOrder, @LastBoardNumber AS LastBoardNumber

SET STATISTICS IO ON
SET STATISTICS TIME ON
-- Using EXISTS to filter is slightly better.
SELECT 	
	SUM(BB.ColumnValue) AS SumOfAllUnmarkedNumbers,
	PN.PickedNumber AS LastPickedNumber,
	SUM(BB.ColumnValue) * PN.PickedNumber AS Result
FROM #BingoBoards BB
JOIN #PickedNumbers PN
	ON PN.PickOrder = @LastPickOrder
WHERE NOT EXISTS(SELECT PN2.PickedNumber FROM #PickedNumbers PN2 WHERE PN2.PickOrder <= @LastPickOrder AND PN2.PickedNumber = BB.ColumnValue)
AND BB.BoardNumber = @LastBoardNumber
GROUP BY PN.PickedNumber

-- LEFT JOIN to filter.
SELECT 	
	SUM(BB.ColumnValue) AS SumOfAllUnmarkedNumbers,
	PN.PickedNumber AS LastPickedNumber,
	SUM(BB.ColumnValue) * PN.PickedNumber AS Result
FROM #BingoBoards BB
JOIN #PickedNumbers PN
	ON PN.PickOrder = @LastPickOrder
LEFT JOIN #PickedNumbers PN2
	ON PN2.PickOrder <= @LastPickOrder
	AND PN2.PickedNumber = BB.ColumnValue
WHERE PN2.PickOrder IS NULL
AND BB.BoardNumber = @LastBoardNumber
GROUP BY PN.PickedNumber

SET STATISTICS IO OFF
SET STATISTICS TIME OFF