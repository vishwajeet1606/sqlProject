-- Covid 19 data exploration

select *from covid19..CovidDeaths$
where continent is not null
order by location,date

-- selecting the relevant data on which we will be working
Select Location, date, total_cases, new_cases, total_deaths, population
From covid19..CovidDeaths$
Where continent is not null 
order by location,date

-- Total cases vs total deaths
-- Chances of demise if someone get contracted with covid19
select Location, date, Population, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From Covid19..CovidDeaths$
where location like '%India%'
and continent is not null
order by location, date

-- checking when the first death case came in my country
select Location, date, total_deaths
From Covid19..CovidDeaths$
where location like '%India%' and total_Deaths>0
order by date

-- Total cases vs population
-- shows what percentage of population in my country got infected with covid19
select location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
From Covid19..CovidDeaths$
where location like '%India'
order by 1,2

-- Countries with highest infection rate compared to population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From Covid19..CovidDeaths$
where continent is not null
group by location, population
order by PercentPopulationInfected desc

--checking when the deaths count for a specific country crossed let's say a specific value
select top 1 location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From Covid19..CovidDeaths$
where total_deaths > 10000 and location like '%India'

-- countries with highest death rate compared to population
select location, population, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((cast(total_deaths as int)/population))*100 as PercentPopulationInfected
From Covid19..CovidDeaths$
where continent is not null
group by location, population
order by PercentPopulationInfected desc

-- as total_deaths column is of nvarchar type so we need to typecast it into int type so as to get the accurate numbers

-- continents with  highest death rate compared to population
select continent, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((cast(total_deaths as int)/population)) as PercentPopulationInfected
From Covid19..CovidDeaths$
where continent is not null
group by continent
order by PercentPopulationInfected desc

-- Global Numbers
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathRate
From Covid19..CovidDeaths$
where continent is not null
-- group by date (this will be useful in observing the daily stats)
order by 1,2

-- Looking at total vaccinations and the vaccinations done on a particular date, we can also filter this data by specific country
select d.continent, d.location, d.date, d.population, v.new_vaccinations
From Covid19..CovidDeaths$ d
Join Covid19..CovidVaccinations$ v
    On d.location = v.location
	and d.date = v.date
where d.continent is not null
 -- and v.new_vaccinations is not null  (this will be useful in checking where vaccination started first)
order by 2,3

-- Total Population vs vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) OVER (Partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From Covid19..CovidDeaths$ d
Join Covid19..CovidDeaths$ v
     On d.location = v.location
	 and d.date = v.date
where d.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) OVER (Partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From Covid19..CovidDeaths$ d
Join Covid19..CovidVaccinations$ v
     On d.location = v.location
	 and d.date = v.date
where d.continent is not null
)
select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) OVER (Partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From Covid19..CovidDeaths$ d
Join Covid19..CovidVaccinations$ v
     On d.location = v.location
	 and d.date = v.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) OVER (Partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From Covid19..CovidDeaths$ d
Join Covid19..CovidVaccinations$ v
     On d.location = v.location
	 and d.date = v.date
where d.continent is not null

-- doing query from view
select *from PercentPopulationVaccinated