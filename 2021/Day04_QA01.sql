-- Run Day04_Load_and_Parse_Data.sql first
DECLARE	
	@IsSampleData INT = 0 -- Change to 1 to see the sample result.

DROP TABLE IF EXISTS #PickedNumbers
DROP TABLE IF EXISTS #BingoBoards
DROP TABLE IF EXISTS #Bingooo
CREATE TABLE #PickedNumbers(PickOrder INT, PickedNumber INT)
CREATE TABLE #BingoBoards (BoardNumber INT, RowID INT, ColumnIndex INT, ColumnValue INT)

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

;WITH Drawings AS
(
SELECT 
	BB.BoardNumber,
	BB.ColumnIndex,
	BB.RowID,	
	PN.PickOrder,
	COUNT(*) OVER (PARTITION BY BB.BoardNumber, BB.RowID ORDER BY PN.PickOrder ROWS UNBOUNDED PRECEDING) CurrentRowHit,
	COUNT(*) OVER (PARTITION BY BB.BoardNumber, BB.ColumnIndex ORDER BY PN.PickOrder ROWS UNBOUNDED PRECEDING) CurrentColumnHit	
FROM #BingoBoards BB
JOIN #PickedNumbers PN
	ON BB.ColumnValue = PN.PickedNumber
GROUP BY 
	PN.PickOrder,
	BB.BoardNumber,
	BB.ColumnIndex,
	BB.RowID
)
SELECT 
	TOP (1) D.PickOrder, D.BoardNumber	
INTO #Bingooo
FROM Drawings D
WHERE D.CurrentRowHit = 5 OR D.CurrentColumnHit = 5
ORDER BY D.PickOrder

SELECT 	
	SUM(BB.ColumnValue) AS SumOfAllUnmarkedNumbers,
	PN.PickedNumber,
	SUM(BB.ColumnValue) * PN.PickedNumber AS Result
FROM #BingoBoards BB
JOIN #Bingooo BO
	ON BO.BoardNumber = BB.BoardNumber
JOIN #PickedNumbers PN
	ON PN.PickOrder = BO.PickOrder
WHERE BB.ColumnValue NOT IN (SELECT PN2.PickedNumber FROM #PickedNumbers PN2 WHERE PN2.PickOrder <= BO.PickOrder)
GROUP BY PN.PickedNumber