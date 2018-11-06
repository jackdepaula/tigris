# install tigris with sf support
devtools::install_github("walkerke/tigris")


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
