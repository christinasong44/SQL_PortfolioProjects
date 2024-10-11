select * from PortfolioProject_CS..CovidDeaths
WHERE DATALENGTH(continent)>0 
order by 3,4

-- select what data we will be using
select location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject_CS..CovidDeaths 
WHERE DATALENGTH(continent)>0 
order by 1,2;

-- view fields and respecftive data types
USE PortfolioProject_CS
SELECT COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME ='CovidDeaths'

-- total cases vs total deaths
-- likelihood of dying if contracted COVID in your country

ALTER TABLE PortfolioProject_CS..CovidDeaths
ALTER COLUMN total_cases decimal
ALTER TABLE PortfolioProject_CS..CovidDeaths
ALTER COLUMN total_deaths decimal

SELECT location, date, total_cases, total_deaths, (total_deaths/nullif(total_cases,0))*100 as deathPercentage
FROM PortfolioProject_CS..CovidDeaths 
where location like '%states%'
AND DATALENGTH(continent)>0 
order by 1,2

-- total cases vs population (what % of population contracted COVID)
ALTER TABLE PortfolioProject_CS..CovidDeaths
ALTER COLUMN population bigint

SELECT location, date, total_cases, population, (nullif(total_cases,0)/population)*100 as casePercentage
FROM PortfolioProject_CS..CovidDeaths 
where location like '%states%'
AND DATALENGTH(continent)>0 
order by 1,2


-- countries with highest infection rate compared to population
ALTER TABLE PortfolioProject_CS..CovidDeaths
ALTER COLUMN location VARCHAR(100)

SELECT 
location, population,
max(total_cases) as highestinfectioncount,
max(nullif(total_cases,0)/nullif(population,0))*100 as infecftionrate
FROM PortfolioProject_CS..CovidDeaths 
WHERE DATALENGTH(continent)>0 
group by location, population
order by 4 desc

-- countries with highest death count per population

SELECT 
location, max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject_CS..CovidDeaths 
WHERE DATALENGTH(continent)>0 
group by location
order by TotalDeathCount desc

-- highest death count per population by CONTINENT instead

SELECT 
continent, max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject_CS..CovidDeaths 
WHERE DATALENGTH(continent)>0 
group by continent
order by TotalDeathCount desc

-- global numbers
ALTER TABLE PortfolioProject_CS..CovidDeaths
ALTER COLUMN new_cases decimal
ALTER TABLE PortfolioProject_CS..CovidDeaths
ALTER COLUMN new_deaths decimal

SELECT date, sum(new_deaths) as new_deaths,sum(new_cases) as new_cases,
case when sum(new_cases)=0 then 0 else sum(new_deaths)/sum(new_cases)*100
end as deathpercentage
FROM PortfolioProject_CS..CovidDeaths 
where DATALENGTH(continent)>0
group by date
order by 1,2

-- global numbers (+) across all dates
SELECT sum(new_deaths) as new_deaths,sum(new_cases) as new_cases,
case when sum(new_cases)=0 then 0 else sum(new_deaths)/sum(new_cases)*100
end as deathpercentage
FROM PortfolioProject_CS..CovidDeaths 
where DATALENGTH(continent)>0
order by 1,2




-- join tables on location and date
-- looking at total population vs vaccination (cumulative aggregate)

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM PortfolioProject_CS..CovidDeaths dea
join PortfolioProject_CS..Covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where DATALENGTH(dea.continent)>0
order by 2,3

-- use CTE for above to recognize rollingpeoplevaccinated - create separate table
with PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as 
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rollingpeoplevaccinated
FROM PortfolioProject_CS..CovidDeaths dea
join PortfolioProject_CS..Covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where DATALENGTH(dea.continent)>0)
select *, (nullif(rollingpeoplevaccinated,0)/population)*100 as VaccinatedPopulationPercentage from PopvsVac
order by 7 desc

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar (255),
location nvarchar(255),
date datetime,
population BIGINT,
new_vaccinations BIGINT,
rollingpeoplevaccinated BIGINT
)

Insert Into #PercentPopulationVaccinated

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM PortfolioProject_CS..CovidDeaths dea
join PortfolioProject_CS..Covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where DATALENGTH(dea.continent)>0

select *,
(nullif(rollingpeoplevaccinated,0)/population)*100 
from #PercentPopulationVaccinated

-- creating view to store data later for visualizations

Create View PercentPopulationVaccinated as

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM PortfolioProject_CS..CovidDeaths dea
join PortfolioProject_CS..Covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where DATALENGTH(dea.continent)>0

Select * from PercentPopulationVaccinated