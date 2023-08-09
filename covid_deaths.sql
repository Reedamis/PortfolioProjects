-- All data was aquired via https://ourworldindata.org/covid-deaths

-- Querying 'Covid_Deaths_2' table to ensure data upload was successful.
-- Filtering out rows with no continent and sorting by location and date columns.

Select *
FROM [Covid DA]..Covid_Deaths_2
WHERE continent is not NULL
ORDER BY 3, 4

-- Querying 'Covid_Deaths_2' to determine the mortality rate from total cases in the US.
-- This provides insight into the fatality risk upon contracting the virus in the US.

SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 AS death_percentage
FROM [Covid DA]..Covid_Deaths_2
WHERE location = 'United States'
ORDER BY 1, 2 ASC;

-- Querying 'Covid_Deaths_2' to gauge how the number of cases compares to the US population.
-- This calculates the percentage of the population that has contracted the virus.

SELECT
    location,
    date,
	population,
    total_cases,
	(total_cases/population)*100 AS percent_of_pop
FROM [Covid DA]..Covid_Deaths_2
WHERE location = 'United States'
ORDER BY 1, 2 ASC;

-- Querying 'Covid_Deaths_2' to identify countries with the highest infection rate.
-- This calculates the maximum percentage of a country's population that has contracted the virus.

SELECT
    location,
	population,
    MAX(total_cases) as highest_infection_count,
	MAX((total_cases/population))*100 AS case_percentage
FROM [Covid DA]..Covid_Deaths_2
WHERE continent is not NULL
AND location NOT LIKE '%income%'
AND location not like '%World%'
GROUP BY location, population
ORDER BY 4 DESC;

-- Querying 'Covid_Deaths_2' to rank countries by their highest death count.
-- This highlights countries with the most fatalities due to the virus.

SELECT
    location,
    MAX(total_deaths) as total_death_count
FROM [Covid DA]..Covid_Deaths_2
WHERE continent is not NULL
GROUP BY location
ORDER BY 2 DESC;
 
-- Querying 'Covid_Deaths_2' to determine continents with the highest death count.
-- This filters out non-continent locations and ranks continents based on the number of fatalities.

SELECT
    location,
    MAX(total_deaths) as total_death_count
FROM [Covid DA]..Covid_Deaths_2
WHERE continent IS NULL AND location NOT LIKE '%income%' AND location not like '%World%'
GROUP BY location
ORDER BY 2 DESC;

-- Creating a view of the previous query to store data for Tableau Visualization.

CREATE VIEW DeathByContinent AS
SELECT
    location,
    MAX(total_deaths) AS total_death_count
FROM [Covid DA]..Covid_Deaths_2
WHERE continent IS NULL 
AND location NOT LIKE '%income%' 
AND location NOT LIKE '%World%'
GROUP BY location;

--Querying 'DeathByContinent' view to ensure creation was successful.

SELECT *
FROM DeathByContinent

-- Querying 'Covid_Deaths_2' to calculate global metrics on new cases and deaths.
-- This provides a global mortality rate for recent cases, filtering out non-country specific data.

SELECT
    date,
    SUM(new_cases) as total_new_cases,
    SUM(new_deaths) as total_new_deaths,
    (SUM(new_deaths) * 100.0) / NULLIF(SUM(new_cases), 0) AS new_death_percentage
FROM [Covid DA]..Covid_Deaths_2
WHERE continent is not null
AND location NOT LIKE '%income%'
AND location not like '%World%'
GROUP BY date
ORDER BY 1, 2;

-- Using a Common Table Expression (CTE) named 'PopvsVac' to calculate rolling totals of vaccinations, including booster doses, for each location and date.
-- The main query then calculates the percentage of the population that has been vaccinated.
-- We join 'Covid_Deaths_2' for demographic data with 'Covid_Vaccinations' for vaccination statistics, and filter out non-country specific entries.

;With PopvsVac (continent, location, date, population, new_vaccinations, people_vaccinated, rolling_total_vaccinations_and_boosters)
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	vac.people_vaccinated,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) AS rolling_total_vaccinations_and_boosters
FROM [Covid DA]..Covid_Deaths_2 dea
JOIN [Covid DA]..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
AND dea.location NOT LIKE '%income%'
AND dea.location not like '%World%'
)
SELECT
	*,
	((people_vaccinated)*100/population) as pop_percent_vaccinated
FROM PopvsVac