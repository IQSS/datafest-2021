
# install packages if needed
if (!require("dataverse")) { install.packages("dataverse") }
if (!require("tidyverse")) { install.packages("tidyverse") }

library(dataverse)
library(tidyverse)

# specify the Digital Object Identifier (DOI) for the dataset
DOI <- "doi:10.7910/DVN/HIDLTK"

# specify version to ensure the file doesn't change
dataset_version = 47

# retrieve the contents of the dataset
covid <- get_dataset(DOI, version = dataset_version)

# view contents
glimpse(covid, max.level = 1)

# view available files
covid$files$filename

# get data file for COVID-19 cases
US_cases_file <- get_file("us_state_confirmed_case.tab", dataset = DOI)

# read the data into a data frame
US_cases <- read_csv(US_cases_file)

# inspect the data
head(US_cases) # 50 states plus D.C. by 364 days
