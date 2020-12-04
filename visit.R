
sql <- "SELECT \"ACCOUNT\"
               FROM \"cona-reporting.field-sales::Q_CA_R_SpringVisit\"
         WHERE
         \"PLANNEDSTART\" >= ? and
         \"PLANNEDSTART\" <= ? AND
         \"STATUS\" = ? AND
         \"VISITTYPE\" = ?"

param1 <- paste(Sys.Date() - 1 - months(6), "00:00:00") # Go 6 months back
param2 <- paste(Sys.Date() - 1, "00:00:00") # yesterday
param3 <- "FINAL"
param4 <- "ZA"

visit_count_last_six_months <- dbGetQuery(jdbcConnection, sql,
                    param1,
                    param2,
                    param3,
                    param4) %>%
  group_by(ACCOUNT) %>%
  count() %>%
  ungroup() %>%
  mutate(CustomerNumber = as.numeric(ACCOUNT)) %>%
  select(-c(ACCOUNT)) %>%
  rename(visit_count_last_six_months = n)

param1 <- paste(Sys.Date() - 1 - months(3), "00:00:00") # Go 3 months back

visit_count_last_three_months <- dbGetQuery(jdbcConnection, sql,
              param1,
              param2,
              param3,
              param4) %>%
  group_by(ACCOUNT) %>%
  count() %>%
  ungroup() %>%
  mutate(CustomerNumber = as.numeric(ACCOUNT)) %>%
  select(-c(ACCOUNT)) %>%
  rename(visit_count_last_three_months = n)

df <- df %>%
  left_join(visit_count_last_six_months, by = "CustomerNumber") %>%
  mutate(visit_count_last_six_months_per_invoice_rn = visit_count_last_six_months / l6_invcnt) %>%
  left_join(visit_count_last_three_months, by = "CustomerNumber") %>%
  mutate(visit_count_last_three_months_per_invoice_rn = visit_count_last_three_months / l3_invcnt)

rm(list=ls()[! ls() %in% c("df","jdbcConnection", "jdbcDriver")])
