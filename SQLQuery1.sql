Drop Table if exists #Percent_Population_Vaccinated
Create Table #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

Select * 
from PortfolioProject..CovidDeaths
Where continent is not NULL
order by 3,4

--Select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths
Where continent is not NULL
order by 1,2

--Looking at Total Cases vs Total Deaths
--Filter = Where; Like = Contains

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
Where location like '%states'
and continent is not NULL
order by 1,2

--Total Cases vs Population

Select location, date, population, total_cases, total_deaths, (total_cases/population)*100 as Percent_Population_Infected
from PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not NULL
order by 1,2


--Countries with Highest Infection Rate compared to Population

Select location, population, MAX (total_cases) as Highest_Infection_Count, MAX ((total_cases/population))*100 as Percent_Population_Infected
from PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not NULL
Group by location, population
order by Percent_Population_Infected desc

-- Countries with Highest Death Count per Population

Select location, MAX (cast(total_deaths as int)) as Total_Death_Count 
from PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not NULL
group by location
order by Total_Death_Count desc


-- Break down by Continent
--Group is like a Pivot Table

Select continent, MAX (cast(total_deaths as int)) as Total_Death_Count 
from PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is  not NULL
group by continent
order by Total_Death_Count desc


-- GLOBAL NUMBERS

Select  SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as total_percent
from PortfolioProject..CovidDeaths
--Where location like '%states'
where continent is not NULL
--group by date
--order by 1,2

--JOIN is like a LOOKUP
-- Total Population vs Total Vaccination
-- if SUM does not work try casting the columns as int

Select dea.continent, dea.location, dea.date, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location) as Total
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- Using CONVERT
--Rolling Count

Select dea.continent, dea.location, dea.date, vac.new_vaccinations
, SUM (Convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/dea.population)
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- USE CTE (Common Table Expression)

With pop_vs_vac (Continent, Location, Date, Population, new_vaccinations, Rolling_People_Vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM (Convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/dea.population)
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
Select *,(Rolling_People_Vaccinated/Population)*100 as Sth
from pop_vs_vac

-- TEMP TABLE



Insert Into #Percent_Population_Vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM (Convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/dea.population)
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

Select *,(Rolling_People_Vaccinated/Population)*100 as Sth
from #Percent_Population_Vaccinated

--Create View

Use PortfolioProject
Go
Create View Percent_Population_Vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM (Convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/dea.population)
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3


 