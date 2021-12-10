-- Data is from 1/1/2020 to 12/2/2021
SELECT * 
FROM Portfolio.dbo.covid_deaths 
ORDER BY location, date;

-- TABLEAU TABLE 1 (Global Numbers)
-- World cases, deaths, and death percentage 
SELECT SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS BIGINT)) AS total_deaths,
	(SUM(CAST(new_deaths AS BIGINT)) / SUM(new_cases)) * 100 AS death_rate_percentage
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NOT NULL;

-- World death rate from covid
SELECT date,
	SUM(new_cases) AS world_new_cases,
	SUM(CAST(new_deaths AS BIGINT)) AS world_new_deaths,
		SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS daily_death_percentage,
	SUM(total_cases) AS world_total_cases,
	SUM(CAST(total_deaths AS BIGINT)) AS world_total_deaths,
	SUM(CAST(total_deaths AS INT)) / SUM(total_cases) * 100 AS total_death_percentage
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Daily cases and death count per country
SELECT location, 
	date, 
	new_cases, 
	total_cases, 
	new_deaths, 
	total_deaths
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NOT NULL
	AND population IS NOT NULL
ORDER BY location, date;

-- Countries with highest death rate
SELECT location,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS death_rate_percentage
FROM Portfolio.dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM Portfolio.dbo.covid_deaths)
	AND total_cases >= 100
	AND continent IS NOT NULL
ORDER BY death_rate_percentage DESC;

-- Daily death percentage per country
SELECT location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases) * 100 AS death_percentage
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NOT NULL
	AND population IS NOT NULL
ORDER BY location, date;

-- Likelihood of dying from covid in United States
SELECT location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS death_percentage
FROM Portfolio.dbo.covid_deaths
WHERE location = 'United States'
	AND population IS NOT NULL
ORDER BY location, date;

-- TABLEAU TABLE 3 (Percent of Population Infected Per Country)
-- % of population infected and dead from covid for each country
SELECT location,
	population,
    total_cases,
    total_deaths,
    (total_cases / population) * 100 AS population_infected_percentage,
    (total_deaths / population) * 100 AS population_dead_from_covid_percentage
FROM Portfolio.dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM Portfolio.dbo.covid_deaths)
	AND total_cases IS NOT NULL
	AND continent IS NOT NULL
ORDER BY location;

-- TABLEAU TABLE 4 (Percent of Population Infected Over Time)
-- % of population that had covid in each country (daily count)
SELECT location,
	date,
	population,
	total_cases,
	(total_cases / population) * 100 AS percent_of_population_infected
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NOT NULL
	AND population IS NOT NULL
ORDER BY percent_of_population_infected DESC;

-- Countries with highest % of population infected
SELECT location,
	total_cases,
	population,
	(total_cases / population) * 100 AS population_infected_percentage
FROM Portfolio.dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM Portfolio.dbo.covid_deaths)
	AND continent IS NOT NULL
	AND population IS NOT NULL
ORDER BY population_infected_percentage DESC;

-- Countries with highest % of population dead from covid
SELECT location,
	total_deaths,
	population,
	(total_deaths / population) * 100 AS population_dead_from_covid_percentage
FROM Portfolio.dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM Portfolio.dbo.covid_deaths)
	AND continent IS NOT NULL
ORDER BY population_dead_from_covid_percentage DESC;

-- Countries with most recorded covid deaths
SELECT location, 
	CAST(total_deaths AS INT) AS covid_deaths
FROM Portfolio.dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM Portfolio.dbo.covid_deaths)
	AND continent IS NOT NULL
	AND population IS NOT NULL
ORDER BY covid_deaths DESC;

-- TABLEAU TABLE 2 (Covid Deaths by Continent)
-- Covid cases/deaths by continent
Select location, 
	SUM(new_cases) AS total_infections,
	SUM(CAST(new_deaths AS BIGINT)) AS total_deaths
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NULL 
AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
Group BY location
ORDER BY total_deaths DESC;

-- Covid infections/deaths by income level
SELECT location AS income_level,
	SUM(new_cases) AS infections,
	SUM(CAST(new_deaths AS BIGINT)) AS deaths
FROM Portfolio.dbo.covid_deaths
WHERE continent IS NULL
	AND location IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY deaths DESC;

-- Introducing vaccinations table
-- United States vaccination statistics
SELECT *
FROM Portfolio.dbo.covid_vaccinations
WHERE location = 'United States';

-- Join both tables
SELECT *
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE population IS NOT NULL;

-- Counting how many vaccinated over time in each country
-- Use PARTITION to create a rolling count of vaccinations
SELECT d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_vaccinations
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.population IS NOT NULL;

-- Vaccinations per population over time (CTE)
WITH PopulationVaccinated (location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_vaccinations
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.population IS NOT NULL
)
SELECT *, 
	total_vaccinations / population AS vaccinations_per_person
FROM PopulationVaccinated;

-- Most vaccinations per population as of 12/2/2021 (Temporary Table)
-- Create temp table:
DROP TABLE IF EXISTS #CurrentPopulationVaccinated
CREATE TABLE #CurrentPopulationVaccinated
(
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
total_vaccinations NUMERIC
)
INSERT INTO #CurrentPopulationVaccinated
SELECT d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_vaccinations
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.population IS NOT NULL;

-- Use temp table to query for countries with most vaccinations per population:
SELECT location,
	population,
	total_vaccinations,
	total_vaccinations / population AS vaccinations_per_person
FROM #CurrentPopulationVaccinated
WHERE date = (SELECT MAX(date) FROM #CurrentPopulationVaccinated)
ORDER BY vaccinations_per_person DESC;

-- Views: will store data for future visualizations
DROP VIEW IF EXISTS PopulationVaccianted;
GO 
-- View 1: Vaccinations per population over time
CREATE VIEW PopulationVaccinated AS 
SELECT d.continent,
	d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_vaccinations
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.population IS NOT NULL;

GO

SELECT *
FROM PopulationVaccinated;

DROP VIEW IF EXISTS AgeVsDeathRate;
GO
-- View 2: Impact of age on covid death percentage
CREATE VIEW AgeVsDeathRate AS 
SELECT d.location,
	d.population,
	d.total_deaths,
	(d.total_deaths / d.population) * 100 AS population_dead_from_covid_percentage,
	v.median_age,
	v.aged_65_older,
	v.aged_70_older
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent IS NOT NULL AND
	d.population IS NOT NULL AND
	d.date = (SELECT MAX(date) FROM Portfolio.dbo.covid_deaths);

GO

SELECT *
FROM AgeVsDeathRate
ORDER BY population_dead_from_covid_percentage DESC;

DROP VIEW IF EXISTS UnitedStatesCovid;
GO
-- View 3: United States Covid Infections, Deaths, and Vaccinations
CREATE VIEW UnitedStatesCovid AS
SELECT d.location,
    d.date,
	d.population,
    d.total_cases,
    d.total_deaths,
    (d.total_deaths / d.total_cases) * 100 AS death_percentage,
	v.new_vaccinations,
	v.people_vaccinated,
	v.people_fully_vaccinated,
	v.total_boosters,
	(v.people_vaccinated / d.population) * 100 AS percent_vaccinated,
	(v.people_fully_vaccinated / d.population) * 100 AS percent_fully_vaccinated
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.location LIKE '%States%'
	AND d.population IS NOT NULL;

GO

SELECT *
FROM UnitedStatesCovid;

DROP VIEW IF EXISTS CountryCovidData;
GO
-- View 4: Covid Infections, Deaths, and Vaccinations for all countries
CREATE VIEW CountryCovidData AS
SELECT d.location,
    d.date,
	d.population,
    d.total_cases,
    d.total_deaths,
    (d.total_deaths / d.total_cases) * 100 AS death_percentage,
	v.new_vaccinations,
	v.people_vaccinated,
	v.people_fully_vaccinated,
	v.total_boosters,
	(v.people_vaccinated / d.population) * 100 AS percent_vaccinated,
	(v.people_fully_vaccinated / d.population) * 100 AS percent_fully_vaccinated
FROM Portfolio.dbo.covid_deaths d
JOIN Portfolio.dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.population IS NOT NULL
	AND d.continent IS NOT NULL;

GO

SELECT *
FROM CountryCovidData;
