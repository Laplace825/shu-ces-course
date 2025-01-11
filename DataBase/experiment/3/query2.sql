SELECT 
    Year,
    Education_Level_Code,
    ROUND(AVG(Average_Age_of_Mother_years), 1) as Average_Age_of_Mother_year
FROM birthratetable
GROUP BY Year, Education_Level_Code
ORDER BY Year, Education_Level_Code;
