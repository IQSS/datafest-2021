#DATA VISUALIZATION


#Our first part will be devoted to creating simple charts and graphs using the wonderful data viz
#library ggplot2. 

#IQSS and HBS collaborate on delivering a workshop devoted to ggplot2 each semester and the 
#workshop materials can be accessed here: https://iqss.github.io/dss-workshops/Rgraphics.html.

#Let's take another look at the data we'll be working with to make our first graphs:
head(US_cases_long)

#Now we'll create a line graph of covid cases rates over time
ggplot(US_cases_long, aes(x = date, y = cases_rate_100K)) +
  geom_line() +
  theme_classic()

#Now let's make a totally goooorgeous graph:
ggplot(US_cases_long, aes(x = date, y = cases_rate_100K, group=state, color=state)) +
  geom_line() +
  theme_classic()

#Time to break it down by state: create line graphs of covid cases rates for each state
ggplot(US_cases_long, aes(x = date, y = cases_rate_100K)) +
  geom_line() +
  facet_wrap(c("state"), ncol = 10, scales = "fixed") +
  theme_classic() +
  theme(axis.title.x=element_blank(), #because these graphs are too small to see x-axis labels
        axis.text.x=element_blank())

#We can also look at cumulative cases. Here's a line graph of cumulative covid cases:
ggplot(US_cases_long, aes(x = date, y = cases_cum_rate_100K)) +
  geom_line() +
  theme_classic()

#Then we can break it down by state by faceting
# line graphs of cumulative covid cases rates for each state
ggplot(US_cases_long, aes(x = date, y = cases_cum_rate_100K)) +
  geom_line() +
  facet_wrap(~ state, scales = "fixed") +
  theme_classic() +
  theme(axis.title.x=element_blank(), #because these graphs are too small to see x-axis labels
      axis.text.x=element_blank())



#MAKING MAPS IN R
#A great way to visualize spatial relationships in data is to superimpose variables onto a map. 
#For some datasets, this could involve superimposing points or lines. For our state-level data, 
#this will involve coloring state polygons in proportion to a variable of interest that represents 
#an aggregate summary of a geographic characteristic within each state. Basically, we're going 
#to create a familiar filled-in map shaded according the severity of the outbreak in the last week.
#Fun fact: this kind of graph is called a "choropleth map." 

#To create a choropleth map we first need to acquire shapefiles that contain spatial data about U.S.
#state-level geographies.There are many different ways of doing this, but today we'll use the 
#tigris package to get Census Tiger shapefiles for census geographies. 
#In particular, we will use the states() function to get state-level geographies, 
#and coastal boundaries can be gathered with the argument cb = TRUE:

#Start by downloading state-level census geographies
us_state_geo <- tigris::states(class = "sf", cb = TRUE) %>%
  # rename `NAME` variable to `state`
  rename(state = NAME)
glimpse(us_state_geo)

glimpse(US_cases_long_week)

# merge weekly COVID-19 cases with spatial data
US_cases_long_week_spatial <- us_state_geo %>% 
  left_join(US_cases_long_week, by = c("state")) %>% 
  filter( state != "Alaska" & state != "Hawaii") 

glimpse(US_cases_long_week_spatial)

US_cases_long_week_spatial %>% 
  # subset data for only latest week
  filter(week_of_year == max(week_of_year, na.rm = TRUE)) %>% 
  # map starts here
  ggplot(aes(fill = cases_rate_100K, color = cases_rate_100K)) +
  geom_sf() +
  coord_sf(crs = 5070, datum = NA) +
  scale_fill_viridis(direction = 1, name = "Case rate\n(per 100K population)") + 
  #scale_color_viridis(direction = -1, name = "Case rate\n(per 100K population)") +
  labs(title = "COVID-19 case rates for last week",
       caption = "Data Sources: Harvard Dataverse, 2020; U.S. Census Bureau, 2019")

#Interactive mapping in R using Leaflet and mapview.

# set some options for the graph
mapviewOptions(fgb = FALSE, # set to FALSE to embed data directly into the HTML
               leafletWidth = 800,
               legend.pos = "bottomright")

# create map
USmap <- US_cases_long_week_spatial %>% 
  # subset data for only latest week
  filter(week_of_year == max(week_of_year, na.rm = TRUE)) %>%
  # map starts here
  mapview(zcol = "cases_rate_100K", layer.name = "Case rates (per 100K)")

# print map
USmap@map
