library(emdi)

##  Set the working directory
setwd("C:/Users/t.i.ferreira/Documents/Small Area Estimation")

##read in the prepared data 
smp <- read.csv("samp_data.csv")
pop <- read.csv("pop_data.csv")

##combine the two datasets using function in EMDI
combined_data <- combine_data( pop_data = pop, pop_domains = "dc",
                               smp_data = smp, smp_domains = "dc")

##read in the map of DCs
library(sp) 
library(rgdal)
map <- readOGR("./mapdata-sa/DC_SA_2011", "DC_SA_2011")

##rename variable to match other data
names(map)[names(map)=="DC_MDB_C"] <- "dc"

##order map data to match other data
map <- map[order(map$dc),]

##merge in sample data to the shapefile
map_smp <- merge(map, smp, by.x = "dc", by.y = "dc", all.x = F)

#generate indicators of spatial dependance

library("spdep")
neighbours <- poly2nb(map_smp, row.names = map_smp$dc)
weight_matrix <- nb2mat(neighbours, style = "W", zero.policy = TRUE)


spatialcor.tests(direct = combined_data$unempl_b4, corMatrix = weight_matrix)

hunger <- fh(fixed = hunger ~ age_cohort_1 + race_1 + urban + q_3 + q_4 + hhsize, 
                 vardir = "hunger_var", combined_data = combined_data,
                 domains = "dc", method = "ml", transformation = "arcsin", backtransformation = "naive", eff_smpsize="hunger_n", MSE = TRUE,
                 mse_type = "boot")

water <- fh(fixed = no_water ~ race_2 + urban + q_3 + q_4 + hhsize, 
             vardir = "no_water_var", combined_data = combined_data,
             domains = "dc", method = "ml", transformation = "arcsin", backtransformation = "naive", eff_smpsize="no_water_n", MSE = TRUE,
             mse_type = "boot")

no_access <- fh(no_access_med ~ mobile_data + race_3 + q_3  + headage + prov_1 + prov_2 + prov_3 + prov_4 + prov_5 + prov_7 + prov_8 + prov_9, 
            vardir = "no_access_med_var", combined_data = combined_data,
            domains = "dc", method = "ml", eff_smpsize="no_access_med_n", MSE = TRUE, transformation = "arcsin", backtransformation = "naive",
            mse_type = "boot")




View(merge(hunger$ind, hunger$MSE,by ="Domain"))



map_plot(object = hunger, indicator="FH", map_obj = map, map_dom_id = "dc")

map_plot(object = water, indicator="FH", map_obj = map, map_dom_id = "dc")

map_plot(object = no_access, indicator="FH", map_obj = map, map_dom_id = "dc")











