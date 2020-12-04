write_rds(df, "data.Rds")

rm(list=ls()[! ls() %in% c("df")])

dataset <- readRDS("data.Rds")

library(tidyverse)

dataset <- dataset %>%
  filter(TradeChannel == 18 |
           TradeChannel == 19 |
           TradeChannel == 20 |
           TradeChannel == 147) %>%
  filter(Tradename == "99999") %>%
  filter(l6_invcnt > 0)

dataset <- dataset %>%
  mutate(Ft_dt_gap = as.numeric(Ft_dt_gap),
         Feature_period_gap = as.numeric(Feature_period_gap))
