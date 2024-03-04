/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From Projects..CovidDeaths
Where continent is not null 
order by 3,4


-- Starting data selection with specific columns

Select Location Country, date ReportDate, total_cases, new_cases, total_deaths, population
From Projects..CovidDeaths
Where continent is not null 
order by 1,2


-- Analyzing death percentage among total cases for a specific region

SELECT location AS Country, date AS ReportDate, total_cases, total_deaths, 
       (total_deaths * 100.0 / total_cases) AS DeathRate
FROM Projects..CovidDeaths 
WHERE location LIKE '%states%' AND continent IS NOT NULL  
order by 1,2


-- Infection rate in terms of total cases against population

SELECT location AS Country, date AS ReportDate, population, total_cases,
       (total_cases * 100.0 / population) AS InfectionRate
FROM Projects..CovidDeaths
ORDER BY Country, ReportDate


-- Highest infection rate by population per country

SELECT location AS Country, population, MAX(total_cases) AS MaxInfectionCount,
       MAX(total_cases * 100.0 / population) AS MaxInfectionRate
FROM Projects..CovidDeaths
GROUP BY location, population
ORDER BY MaxInfectionRate DESC


-- Highest death count per country normalized by population

SELECT location AS Country, MAX(CONVERT(INT, total_deaths)) AS MaxDeathCount
FROM Projects..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY MaxDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT
-- Continent-wise highest death count

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Projects..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- Global Covid statistics

SELECT SUM(new_cases) AS GlobalCases, SUM(CONVERT(INT, new_deaths)) AS GlobalDeaths,
       SUM(CONVERT(INT, new_deaths)) * 100.0 / SUM(new_cases) AS GlobalDeathRate
FROM Projects..CovidDeaths
WHERE continent IS NOT NULL 
order by 1,2


-- Population versus vaccinations, showcasing rolling sum of vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS CumulativeVaccinations
FROM Projects..CovidDeaths cd
INNER JOIN Projects..CovidVaccinations cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
ORDER BY cd.location, cd.date


-- Using CTE to perform Calculation on Partition By in previous query

WITH VaccinationStats AS (
    SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
           SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS CumulativeVaccinations
    FROM Projects..CovidDeaths cd
    INNER JOIN Projects..CovidVaccinations cv ON cd.location = cv.location AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL 
)
SELECT *, (CumulativeVaccinations * 100.0 / Population) AS VaccinationPercentage
FROM VaccinationStats


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #VaccinationCoverage;
CREATE TABLE #VaccinationCoverage (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    CumulativeVaccinations NUMERIC
);

INSERT INTO #VaccinationCoverage
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS CumulativeVaccinations
FROM Projects..CovidDeaths cd
JOIN Projects..CovidVaccinations cv ON cd.location = cv.location AND cd.date = cv.date

SELECT *, (CumulativeVaccinations * 100.0 / Population) AS VaccinationPercentage
FROM #VaccinationCoverage


-- Creating View to store data for later visualizations
 
CREATE OR ALTER VIEW VaccinationCoverageView AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS CumulativeVaccinations
FROM Projects..CovidDeaths cd
JOIN Projects..CovidVaccinations cv ON cd.location =cv.location and cd.date=cv.date
where cd.continent is not null

