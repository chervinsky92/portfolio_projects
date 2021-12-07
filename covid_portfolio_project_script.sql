-- Data is from 1/1/2020 to 12/2/2021

SELECT * 
FROM dbo.covid_deaths 
ORDER BY location, date;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total cases vs total deaths per country
SELECT location,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS death_percentage
FROM dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM dbo.covid_deaths)
	AND total_cases >= 1000
	AND continent IS NOT NULL
ORDER BY death_percentage DESC;

-- Total cases vs total deaths per country (daily)
SELECT location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases) * 100 AS death_percentage
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Likelihood of dying from covid in United States
SELECT location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS death_percentage
FROM dbo.covid_deaths
WHERE location LIKE '%States%'
ORDER BY location, date;

-- Total cases/deaths vs population
SELECT location,
    total_cases,
    total_deaths,
    population,
    (total_cases / population) * 100 AS population_infected_percentage,
    (total_deaths / population) * 100 AS population_dead_from_covid_percentage
FROM dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM dbo.covid_deaths)
	AND total_cases IS NOT NULL
	AND continent IS NOT NULL
ORDER BY location;

-- Countries with highest infection rate in relation to population size
SELECT location,
	total_cases,
	population,
	(total_cases / population) * 100 AS population_infected_percentage
FROM dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM dbo.covid_deaths)
	AND continent IS NOT NULL
ORDER BY population_infected_percentage DESC;

-- Countries with most recorded covid deaths
SELECT location, 
	CAST(total_deaths AS INT) AS total_covid_deaths
FROM dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM dbo.covid_deaths)
	AND continent IS NOT NULL
ORDER BY total_covid_deaths DESC;

-- Countries with highest death count in relation to population size
SELECT location,
	total_deaths,
	population,
	(total_deaths / population) * 100 AS population_dead_from_covid_percentage
FROM dbo.covid_deaths
WHERE date = (SELECT MAX(date) FROM dbo.covid_deaths)
	AND continent IS NOT NULL
ORDER BY population_dead_from_covid_percentage DESC;

-- Covid cases/deaths by continent
SELECT location,
	SUM(CAST(total_cases AS BIGINT)) AS continent_cases,
	SUM(CAST(total_deaths AS BIGINT)) AS continent_deaths
FROM dbo.covid_deaths
WHERE continent IS NULL
	AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY continent_deaths DESC;

-- Alternative query: covid cases/deaths by continent
SELECT continent,
	SUM(CAST(total_cases AS BIGINT)) AS continent_cases,
	SUM(CAST(total_deaths AS BIGINT)) AS continent_deaths
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY continent_deaths DESC;

-- Covid infections/deaths by income level
SELECT location AS income_level,
	SUM(CAST(total_cases AS BIGINT)) AS continent_cases,
	SUM(CAST(total_deaths AS BIGINT)) AS continent_deaths
FROM dbo.covid_deaths
WHERE continent IS NULL
	AND location IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY continent_deaths DESC;

-- Total covid cases and deaths
SELECT date,
	SUM(new_cases) AS world_new_cases,
	SUM(CAST(new_deaths AS BIGINT)) AS world_new_deaths,
		SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS daily_death_percentage,
	SUM(total_cases) AS world_total_cases,
	SUM(CAST(total_deaths AS BIGINT)) AS world_total_deaths,
	SUM(CAST(total_deaths AS INT)) / SUM(total_cases) * 100 AS total_death_percentage
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Introducing vaccinations table
SELECT *
FROM dbo.covid_vaccinations;

-- Join both tables
SELECT *
FROM dbo.covid_deaths d
JOIN dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date;

-- Counting how many vaccinated over time in each country
-- Use PARTITION to create a rolling count of vaccinations
SELECT d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_vaccinations
FROM dbo.covid_deaths d
JOIN dbo.covid_vaccinations v
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
FROM dbo.covid_deaths d
JOIN dbo.covid_vaccinations v
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
FROM dbo.covid_deaths d
JOIN dbo.covid_vaccinations v
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

GO 

CREATE VIEW PopulationVaccinated AS 
SELECT d.continent,
	d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_vaccinations
FROM dbo.covid_deaths d
JOIN dbo.covid_vaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.population IS NOT NULL;

GO

SELECT *
FROM PopulationVaccinated;