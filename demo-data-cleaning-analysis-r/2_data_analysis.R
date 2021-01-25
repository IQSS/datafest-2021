
## Demo covid19 data analysis approaches


library(tidyverse)
library(lubridate)
library(glmmTMB)
library(effects)
library(zoo)
library(fable)

## read data saved in previous step

us_states_covid19 <- read_rds("data/us_states_covid19.rds")

## Time series

us_covid19 <- us_states_covid19 %>%
  group_by(date) %>%
  summarise(cases = sum(cases),
            deaths = sum(deaths))

us_covid19_long <- pivot_longer(us_covid19, cols = c("cases", "deaths"), values_to = "count")

ggplot(us_covid19_long, aes(x = date, y = count)) +
  geom_line() +
  facet_wrap("name", ncol = 1, scales = "free")

## smooth these with rolling mean

us_covid19 <- us_covid19 %>%
  arrange(date) %>%
  mutate(week_cases = rollmean(cases, k = 7, na.pad = TRUE),
         week_deaths = rollmean(deaths, k = 7, na.pad = TRUE))

us_covid19_long <- pivot_longer(us_covid19, 
                                cols = c("cases", "week_cases", "deaths", "week_deaths"), 
                                values_to = "count")

ggplot(us_covid19_long, aes(x = date, y = count)) +
  geom_line() +
  facet_wrap("name", ncol = 1, scales = "free")

us_covid19 <- as_tsibble(us_covid19, index = "date")

fm <- model(us_covid19, ETS(deaths ~ trend("A")))
autoplot(forecast(fm, h = "100 days"), us_covid19)


## cross sectional models

states_covid19_w52 <- filter(us_states_covid19, week_of_pandemic == 52) %>%
  group_by(NAME) %>%
  summarize(across(where(is.numeric), ~mean(.x, na.rm=TRUE)))


summary(select(states_covid19_w52, pop, percent_over65, cases_rate_100k))

plot(select(states_covid19_w52, pop, percent_over65, cases_rate_100k))

cs_mod <- lm(deaths_rate_100k ~ pop + percent_over65 + cases_rate_100k, data = states_covid19_w52)

cs_mod <- cs_mod <- lm(deaths_rate_100k ~ pop + percent_over65*cases_rate_100k, data = states_covid19_w52)

plot(allEffects(cs_mod))

## mixed effects models incorporating spatial and temporal dimensions

states_covid19_week <- us_states_covid19 %>%
  group_by(NAME, week_of_pandemic) %>%
  summarize(across(where(is.numeric), ~mean(.x, na.rm=TRUE))) %>%
  mutate(log_deaths_rate_100k = log(deaths_rate_100k + .01),
         log_cases_rate_100k = log(cases_rate_100k + .01))


hist(log(states_covid19_week$cases_rate_100k))
hist(log(states_covid19_week$deaths_rate_100k))

mmod <- glmmTMB(log_deaths_rate_100k ~ week_of_pandemic * log_cases_rate_100k + percent_over65 +
                  (1 | NAME),
                family = gaussian(link="identity"),
                states_covid19_week)

summary(mmod)

plot(allEffects(mmod))
