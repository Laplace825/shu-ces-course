WITH TotalBirths AS (
    SELECT
        State,
        Year,
        SUM(CASE WHEN Gender = 'M' THEN Number_of_Births ELSE 0 END) as Male_Births,
        SUM(CASE WHEN Gender = 'F' THEN Number_of_Births ELSE 0 END) as Female_Births,
        SUM(Number_of_Births) as Total_Births
    FROM birthratetable
    GROUP BY State, Year
)
SELECT
    State,
    Year,
    CONCAT(ROUND(CAST(Male_Births AS FLOAT) / Total_Births * 100, 2), "%") as MRatio,
    CONCAT(ROUND(CAST(Female_Births AS FLOAT) / Total_Births * 100, 2), "%") as FRatio
FROM TotalBirths
ORDER BY State, Year;
