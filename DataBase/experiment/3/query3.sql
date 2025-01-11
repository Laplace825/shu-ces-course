SELECT 
    Year,
    ROUND(AVG(Average_Birth_Weight_g), 1) as Average_Birth_Weight,
    ROUND(AVG(Average_Age_of_Mother_years), 1) as Average_Age_of_Mother
FROM birthratetable
GROUP BY Year
ORDER BY Year;
