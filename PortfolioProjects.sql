--Select *
--From PortfolioProject..CovidDeaths
--where continent is not null
--order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4



Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Looking at total cases vs total deaths
--shows the likelihood of dying after getting covid
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases) *100 AS DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%australia%'
order by 1,2

--Looking at the number of cases and number of deaths in 2024 in Australia
WITH deathsIn2024 AS (
    SELECT
        (SELECT total_deaths FROM PortfolioProject..CovidDeaths WHERE date = '2024-05-26 00:00:00.000' AND location LIKE '%australia%') AS TotalDeathsEnd2024,
        (SELECT total_deaths FROM PortfolioProject..CovidDeaths WHERE date = '2024-01-01 00:00:00.000' AND location LIKE '%australia%') AS TotalDeathsStart2024,
        (SELECT total_cases FROM PortfolioProject..CovidDeaths WHERE date = '2024-05-26 00:00:00.000' AND location LIKE '%australia%') AS TotalCasesEnd2024,
        (SELECT total_cases FROM PortfolioProject..CovidDeaths WHERE date = '2024-01-01 00:00:00.000' AND location LIKE '%australia%') AS TotalCasesStart2024
)
SELECT
    date,
    total_cases,
    total_deaths,
    (deathsIn2024.TotalDeathsEnd2024 - deathsIn2024.TotalDeathsStart2024) AS TotalDeaths2024,
    (deathsIn2024.TotalCasesEnd2024 - deathsIn2024.TotalCasesStart2024) AS TotalCases2024
FROM
    PortfolioProject..CovidDeaths,
    deathsIn2024
WHERE
    location LIKE '%australia%'
    AND date BETWEEN '2024-01-01 00:00:00.000' AND '2024-06-16 00:00:00.000'
ORDER BY
    date, total_cases;


--Looking at total cases vs population

Select Location, date, total_cases,population, (total_cases/population) *100 AS CaontractionPercentageInPopulation
From PortfolioProject..CovidDeaths
where location like '%australia%'
order by 1,2

--countries with highest infection rate compared to population

Select Location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) *100 AS CaontractionPercentageInPopulation
From PortfolioProject..CovidDeaths
where continent is not null
Group by location, population
order by 4 desc


--Showing countries with the highest death count per population

Select Location,population, MAX(total_deaths) as HighestDeathsCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by location,population
order by HighestDeathsCount desc

--global numbers

Select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths,
sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths

--Population of the world that was vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(COALESCE(CONVERT(BIGINT,vac.new_vaccinations),0)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--with CTE

WITH PopulvsVac ( Continent, Location,Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(COALESCE(CONVERT(BIGINT,vac.new_vaccinations),0)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
from PopulvsVac
order by Location,Date


---TEMP TABLE
Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert Into #PercentPopulationVaccinated
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(COALESCE(CONVERT(BIGINT,vac.new_vaccinations),0)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated
order by Location,Date


---Creating view to store data for visualizations
Create View PercentPopulationVaccinated as
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(COALESCE(CONVERT(BIGINT,vac.new_vaccinations),0)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *
from PercentPopulationVaccinated
WHERE location = 'Australia'