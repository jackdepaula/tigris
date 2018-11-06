# install tigris with sf support
# devtools::install_github("walkerke/tigris")

# install.packages("tmap")
# install.packages("censusapi")

library(tigris)

us <- states()
plot(us)

# How tigris works
# 
# When you call a tigris function, it does the following:
#   
# Downloads your data from the US Census Bureau website
# 
# Stores your data in a user cache directory (via rappdirs) or in a temporary directory
# 
# Loads your data into your R session with rgdal::readOGR() or sf::st_read()

# TIGER/Line vs. cartographic boundary files

ri <- counties("RI")
ri20 <- counties("RI", cb = TRUE, resolution = "20m")
plot(ri)
plot(ri20, border = "red", add = TRUE)

# Example: Zip Code Tabulation Areas (ZCTAs)

fw_zips <- zctas(cb = TRUE, starts_with = "761")
plot(fw_zips)


# Example: roads in Loving County, TX

loving <- roads("TX", "Loving")
plot(loving)

# Combining objects with rbind_tigris

sts <- c("DC", "MD", "VA") 
combined <- rbind_tigris(
  lapply(sts, function(x) {
    tracts(x, cb = TRUE)
  })
)
plot(combined)

# Merging data with geo_join

df <- read.csv("http://personal.tcu.edu/kylewalker/data/txlege.csv",
               stringsAsFactors = FALSE)

districts <- state_legislative_districts("TX", house = "lower", 
                                         cb = TRUE)

names(df)
# [1] "Name"     "District" "City"     "Party"
names(districts)
# [1] "STATEFP"  "SLDLST"   "AFFGEOID" "GEOID"    "NAME"     "LSAD"     "LSY"      "ALAND"    "AWATER"
head(df$District)
head(districts$NAME)

txlege <- geo_join(districts, df, "NAME", "District")

txlege$color <- ifelse(txlege$Party == "R", "red", "blue")
plot(txlege, col = txlege$color)
legend("topright", legend = c("Republican", "Democrat"),
       fill = c("red", "blue"))


# Thematic mapping: the tmap package
# Let's get some data:

Sys.getenv("CENSUS_API_KEY")

library(tigris)
library(censusapi)
library(tidyverse)
library(tmap)
chi_counties <- c("Cook", "DeKalb", "DuPage", "Grundy", "Lake", 
"Kane", "Kendall", "McHenry", "Will County")
chi_tracts <- tracts(state = "IL", county = chi_counties, 
cb = TRUE)
key <- Sys.getenv("CENSUS_API_KEY")
data_from_api <- getCensus(name = "acs5", vintage = 2015, 
key = key, vars = "B25077_001E", 
region = "tract:*", 
regionin = "state:17")

# Static mapping with tmap

values <- data_from_api %>%
  transmute(GEOID = paste0(state, county, tract), 
            value = B25077_001E)
chi_joined = geo_join(chi_tracts, values, by = "GEOID")
tm_shape(chi_joined, projection = 26916) +
  tm_fill("value", style = "quantile", n = 7, palette = "Greens", 
          title = "Median home values \nin the Chicago Area") + 
  tm_legend(bg.color = "white", bg.alpha = 0.6) + 
  tm_style_gray()

# Interactive mapping with tmap
# For an interactive Leaflet map, run:
#   
ttm()

# then run the tmap code as before.
# 
# Simple features for R
# The future of spatial data in R
# 
# Spatial data represented as R data frames, with geometry stored in a list-column
# 
# Learn more: http://edzer.github.io/sfr/
  
# Simple features in tigris
# Add class = "sf" to your tigris function call
# 
# or:
#   
# At the beginning of your script, specify options(tigris_class = "sf")
  
# Exploratory spatial analysis pipelines with sf
# Question: how do home values in the Chicago area vary with distance from downtown?
  
library(sf)
city_hall <- c(-87.631969, 41.883835) %>%
  st_point() %>%
  st_sfc(crs = 4269) %>%
  st_transform(26916)

# Exploratory spatial analysis pipelines with sf

options(tigris_class = "sf")
chi_tracts_sf <- tracts(state = "IL", county = chi_counties, 
                        cb = TRUE)
chi_tracts_sf %>%
  st_transform(26916) %>%
  left_join(values, by = "GEOID") %>%
  mutate(dist = as.numeric(
    st_distance(
      st_centroid(.), city_hall
    )
  )) %>%
  ggplot(aes(x = dist, y = value)) + 
  geom_smooth(span = 0.3, method = "loess")

