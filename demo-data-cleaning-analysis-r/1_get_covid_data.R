
## Retrieves and processes covid19 data from dataverse

library(dataverse)
library(tidyverse)
library(lubridate)
library(tidycensus)


## retrieve data

doi <- "https://doi.org/10.7910/DVN/HIDLTK"

covid_dataset <- get_dataset(doi)


View(covid_dataset$files)

us_states_cases <- read_csv(get_file("us_state_confirmed_case.tab", dataset = doi))
us_states_deaths <- read_csv(get_file("us_state_deaths_case.tab", dataset = doi))


## reshape into long format

us_states_cases <- pivot_longer(us_states_cases, 
                                cols = starts_with("20"), 
                                names_to = "date", 
                                values_to = "cases_cum")

us_states_deaths <- pivot_longer(us_states_deaths, 
                                cols = starts_with("20"), 
                                names_to = "date", 
                                values_to = "deaths_cum")

us_states_covid19 <- full_join(us_states_cases, us_states_deaths)

## sanity check
dim(us_states_cases)
dim(us_states_deaths)
dim(us_states_covid19)


## cleanup
us_states_covid19 <- us_states_covid19 %>%
  select(NAME, POP10, date, cases_cum, deaths_cum)


## census data
apikey <- rstudioapi::askForPassword()

census_api_key(apikey)


age_demog <- get_estimates(
  geography = "state",
  product = "characteristics",
  breakdown = "AGEGROUP",
  breakdown_labels = TRUE,
  year = 2019,
  key = apikey
  )

age_demog <- pivot_wider(age_demog,
                         names_from = AGEGROUP,
                         values_from = value,
                         names_repair = "universal"
)

age_demog <- mutate(
  age_demog,
  percent_over65 = (..65.years.and.over / All.ages) * 100,
  pop = All.ages) %>%
  select(NAME, pop, percent_over65, Median.age)
  
## merge census and covid data

us_states_covid19 <- left_join(us_states_covid19, age_demog)

## compute dates etc.

us_states_covid19 <- us_states_covid19 %>%
  mutate(date = ymd(date),
         year = year(date),
         month_of_year = month(date),
         week_of_year = week(date),
         day_of_year = yday(date)
  )

us_states_covid19 <- us_states_covid19 %>%
  arrange(NAME, date) %>%
  group_by(year, month_of_year) %>%
  mutate(month_of_pandemic = cur_group_id()) %>%
  group_by(year, week_of_year) %>%
  mutate(week_of_pandemic = cur_group_id()) %>%
  group_by(year, day_of_year) %>%
  mutate(day_of_pandemic = cur_group_id())

## compute counts

us_states_covid19 <- us_states_covid19 %>%
  group_by(NAME) %>%
  mutate(cases = cases_cum - lag(cases_cum, default = 0),
         deaths = deaths_cum - lag(deaths_cum, default = 0),
         cases_rate_100k = (cases / pop) * 100000,
         deaths_rate_100k = (deaths / pop) * 100000)

## sanity check

summary(us_states_covid19)


negcounts <- which(us_states_covid19$cases < 0)

View(us_states_covid19[sort(c(negcounts, (negcounts -1))), ])

us_states_covid19[negcounts, "cases"] <- us_states_covid19[negcounts -1, "cases"]

negcounts <- which(us_states_covid19$deaths < 0)

us_states_covid19[negcounts, "deaths"] <- us_states_covid19[negcounts -1, "deaths"]


## Save!

write_rds(us_states_covid19, "data/us_states_covid19.rds")
