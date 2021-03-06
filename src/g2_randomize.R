#==============================================
# 2. Choose the set of ghops to use
#==============================================
library(tidyverse)
library(zoo)

#==== set seed
randID <- as.integer(rand_date) # date run for randomization (maybe include in csV)
set.seed(randID)

#===== import ghop mass data
weighed_g <- read_csv(here::here(paste0('data/ghop_data_wk',week,'.csv')))
weighed_g <- weighed_g[,1:3]
colnames(weighed_g) <- c('ghop_tube', 'tube_mass', 'tube_ghop_mass')

# for week 9.3, a molting ghop to be removed
if (week == 9.3) {
    weighed_g[which(weighed_g$ghop_tube == 'G26'),] <- NA
    weighed_g[which(weighed_g$ghop_tube == 'G01'),] <- NA
}

# import the relevant cages w/ info for the week
cage_alloc <- read_csv(here::here(paste0('results/g1_updated_cages_wk',week,'.csv')))
receiving_ghops <- nrow(filter(cage_alloc, treatment!='control'))
ghops_2weigh <- receiving_ghops + 4

#===== calculate ghop masses
calc_g <- weighed_g %>% 
    mutate(ghop_mass = tube_ghop_mass - tube_mass,
           ghopID = paste0('W',week,".",ghop_tube)) %>% 
    arrange(ghop_mass)


# find_ghop_set <- function(num_ghops, masses) {
#==========
num_ghops <- ghops_2weigh
# fake_masses <- tibble(ghop_mass = runif(30)) %>%
# arrange(ghop_mass)
# g_masses <- fake_masses
g_masses <- calc_g

g_masses <- g_masses %>% 
    mutate(rolled_mean = rollapply(ghop_mass, num_ghops, mean, fill = NA, align='center'),
           rolled_median = rollapply(g_masses$ghop_mass, num_ghops, median, fill = NA, align='center'),
           rolled_diff = rolled_mean - rolled_median)
if(week == 9.3){
    min_matches <- g_masses$rolled_mean - 0.10857
    min_index <- which.min(abs(min_matches)) - floor(num_ghops/2)
} else {
    min_index <- which.min(abs(g_masses$rolled_diff)) - floor(num_ghops/2)
}
max_index <- min_index + num_ghops - 1

g_masses$include <- FALSE
g_masses[min_index:max_index,]$include <- TRUE
g_masses$rando <- runif(nrow(g_masses))

#===== start allocating calibration ghops
g_masses$treatment <- NA
g_masses[min_index:max_index,]$treatment <- 'TBD'
g_masses[min_index,]$treatment <- 'calib'
g_masses[max_index,]$treatment <- 'calib'
q2 <- floor(ghops_2weigh/3 + min_index -1)
q3 <- floor(ghops_2weigh/3*2 + min_index -1)
g_masses[q2,]$treatment <- 'calib'
g_masses[q3,]$treatment <- 'calib'

# }
#===========
g_write <- g_masses %>% 
    filter(include==TRUE) %>% 
    select(ghopID, ghop_mass, rando, treatment)

write_csv(g_write, here::here(paste0('results/g2_ghops_include_wk',week,'.csv')))

all50 <- left_join(calc_g, g_write) %>% 
    arrange(ghopID)
write_csv(all50, here::here(paste0('results/g2_ghops_all_weighed_wk',week,'.csv')))
