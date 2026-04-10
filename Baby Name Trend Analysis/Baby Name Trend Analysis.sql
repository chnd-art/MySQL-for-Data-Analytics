-- OBJECTIVE 1: Track changes in name popularity
-- OBJECTIVE 1: Compare popularity across decades
-- OBJECTIVE 1: Compare popularity across regions
-- OBJECTIVE 1: Explore unique names in the dataset


               -- Track changes in name popularity


-- 1. Find the overall most popular girl name and most popular boy name.
-- Show how they have changed in popularity rankings over the years.
USE baby_names_db;

SELECT * FROM names;

SELECT Name, SUM(Births) AS num_babies
FROM names 
WHERE Gender = 'F'
GROUP BY Name
ORDER BY num_babies DESC
LIMIT 1;

SELECT Name, SUM(Births) AS num_babies
FROM names 
WHERE Gender = 'M'
GROUP BY Name
ORDER BY num_babies DESC
LIMIT 1;

SELECT * FROM
(
    WITH girl_names AS (
        SELECT Year, Name, SUM(Births) AS num_babies
        FROM names 
        WHERE Gender = 'F' AND Year >= 2000
        GROUP BY Year, Name
    )
    SELECT Year, Name,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
    FROM girl_names
) AS popular_girl_names
WHERE Name = 'Jessica';

SELECT * FROM
(
    WITH boy_names AS (
        SELECT Year, Name, SUM(Births) AS num_babies
        FROM names 
        WHERE Gender = 'M' AND Year >= 2000
        GROUP BY Year, Name
    )
    SELECT Year, Name,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
    FROM boy_names
) AS popular_boy_names
WHERE Name = 'Michael';

-- 2. Find the names with the biggest jumps in popularity from the first year

WITH names_1980 AS (

     WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
     FROM names
     GROUP BY Year, Name)
  
     SELECT Year, Name,
            ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
     FROM all_names
     WHERE Year = 1980),

names_2009 AS (
 
     WITH all_names As (SELECT Year, Name, SUM(Births) AS num_babies
     FROM names
     GROUP BY Year, Name)

     SELECT Year, Name,
           ROW_NUMBER() OVER(PARTITION BY Year ORDER BY num_babies DESC) AS popularity
     FROM all_names
     WHERE Year = 2009)

SELECT t1.Year, t1.Name, t1.popularity, t2.Year, t2.Name, t2.popularity,
            CAST(t2.popularity AS SIGNED) - CAST(t1.popularity AS SIGNED) AS diff
FROM names_1980 t1 INNER JOIN names_2009 t2
            ON t1.Name = t2.Name;



-- OBJECTIVE 2: Compare popularity across decades
-- 1. For each year, return the 3 most popular girl names and 3 most popular boy names
WITH babies_by_year AS (
    SELECT 
        Year, 
        Gender, 
        Name, 
        SUM(Births) AS num_babies
    FROM names
    WHERE Year >= 2000   -- 👈 IMPORTANT
    GROUP BY Year, Gender, Name
)

SELECT *
FROM (
    SELECT 
        Year, 
        Gender, 
        Name, 
        num_babies,
        ROW_NUMBER() OVER (
            PARTITION BY Year, Gender 
            ORDER BY num_babies DESC
        ) AS popularity
    FROM babies_by_year
) AS ranked
WHERE popularity <= 3;



                -- 2. For each decade, return the 3 most popular girl names and 3 most popular boy names



WITH babies_by_decade AS (
    SELECT 
        CASE 
            WHEN Year BETWEEN 1980 AND 1989 THEN 'Eighties'
            WHEN Year BETWEEN 1990 AND 1999 THEN 'Nineties'
            WHEN Year BETWEEN 2000 AND 2010 THEN 'Two_Thousands'
            ELSE 'None'
        END AS decade,
        Gender, 
        Name, 
        SUM(Births) AS num_babies
    FROM names
    WHERE Year >= 1990   -- 👈 AJOUT ICI
    GROUP BY decade, Gender, Name
)

SELECT *
FROM (
    SELECT 
        decade, 
        Gender, 
        Name, 
        num_babies,
        ROW_NUMBER() OVER (
            PARTITION BY decade, Gender 
            ORDER BY num_babies DESC
        ) AS popularity
    FROM babies_by_decade
) AS top_three
WHERE popularity < 4;



               -- OBJECTIVE 3 : Compare Popularity Across Region



-- 1. Return the number of babies born in each of the six regions

WITH clean_regions AS (
    SELECT 
        State,
        CASE 
            WHEN Region = 'New England' THEN 'New_England'
            ELSE Region
        END AS clean_region
    FROM regions
    
    UNION
    
    SELECT 
        'MI' AS State, 
        'Midwest' AS clean_region
)

SELECT 
    clean_region, 
    SUM(Births) AS num_babies
FROM names n
LEFT JOIN clean_regions cr
    ON n.State = cr.State
GROUP BY clean_region;

-- 2. Return the 3 most popular girl names and 3 most popular boy names within each region

WITH babies_by_region AS (

    WITH clean_regions AS (
        SELECT 
            State,
            CASE 
                WHEN Region = 'New England' THEN 'New_England'
                ELSE Region
            END AS clean_region
        FROM regions
        
        UNION
        
        SELECT 
            'MI' AS State, 
            'Midwest' AS clean_region
    )

    SELECT 
        cr.clean_region, 
        n.Gender, 
        n.Name, 
        SUM(n.Births) AS num_babies
    FROM names n
    LEFT JOIN clean_regions cr
        ON n.State = cr.State
    GROUP BY cr.clean_region, n.Gender, n.Name
)

SELECT *
FROM (
    SELECT 
        clean_region, 
        Gender, 
        Name,
        ROW_NUMBER() OVER (
            PARTITION BY clean_region, Gender 
            ORDER BY num_babies DESC
        ) AS popularity
    FROM babies_by_region
) AS region_popularity
WHERE popularity < 4;



                -- Objective 4 : Dig Into Some Unique Names



-- 1. Find the 10 most popular androgynous names (names given to both females and males)

SELECT 
    Name, 
    COUNT(DISTINCT Gender) AS num_genders, 
    SUM(Births) AS num_babies
FROM names
GROUP BY Name
HAVING num_genders = 2
ORDER BY num_babies DESC
LIMIT 10;

-- 2. Find the length of the shortedt and longest names.
-- Identify the most popular short names

SELECT Name, LENGTH(Name) AS name_length
FROM names
GROUP BY Name
ORDER BY name_length; -- 2

SELECT Name, LENGTH(Name) AS name_length
FROM names
GROUP BY Name
ORDER BY name_length DESC; -- 15

WITH short_long_names AS (SELECT *
FROM names
WHERE LENGTH(Name) IN (2,15))

SELECT Name, SUM(Births) AS num_babies
FROM short_long_names
GROUP BY Name
ORDER BY num_babies DESC;

-- 3. The founder of our website’s name is Chris. Find the state with the highest percent

SELECT State, num_chris / num_babies * 100 AS pct_chris
FROM

(WITH count_chris AS (SELECT State, SUM(Births) AS num_chris
FROM names
WHERE name = 'Chris'
GROUP BY State),

count_all AS (SELECT State, SUM(Births) AS num_babies
FROM names
GROUP BY State)

SELECT cc.State, cc.num_chris, ca.num_babies
FROM count_chris cc INNER JOIN count_all ca
    ON cc.State = ca.State) AS state_chris_all

ORDER BY pct_chris DESC;
