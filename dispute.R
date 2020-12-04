sql <- "SELECT \"TechnicalCaseKey\",
\"DocumetnNo\",
\"RefKey3\",
\"CaseID\",
\"CreatedDate\",
\"PaperworkTurnAroundTIme\",
\"Customer\" FROM \"cona-reporting.accounts-receivable::Q_CA_R_Disputes\" (
  'PLACEHOLDER' = ('$$Key_Date$$', '2020-09-17 00:00:00') ) \"cona-reporting.accounts-receivable::Q_CA_R_Disputes\" WHERE
\"CreatedDate\" >= ?"

param1 <- Sys.Date() - 1 - months(6)

dispute <- dbGetQuery(jdbcConnection, sql, param1)

# count of disputes last 6 months

dispute_count_last_six <- dispute %>%
  select(Customer, DocumetnNo) %>%
  unique() %>%
  group_by(Customer) %>%
  count(Customer, name = "dispute_count_last_six") %>%
  ungroup() %>%
  mutate(Customer = as.numeric(Customer)) %>%
  rename(CustomerNumber = Customer)

df <- df %>%
  left_join(dispute_count_last_six, by = "CustomerNumber") %>%
  replace(is.na(.), 0) %>%
  mutate(disp_count_last_six_per_invoice = dispute_count_last_six / l6_invcnt)

df <- df %>%
  mutate(disp_l6_pi_cat_High_dispute_l6 = ifelse(disp_count_last_six_per_invoice >= 0.167, 1, 0),
         disp_l6_pi_cat_Low_dispute_l6 = ifelse(disp_count_last_six_per_invoice > 0 & disp_count_last_six_per_invoice < 0.167, 1, 0),
         disp_l6_pi_cat_No_dispute_l6 = ifelse(disp_count_last_six_per_invoice == 0, 1, 0))

rm(list=ls()[! ls() %in% c("df","jdbcConnection", "jdbcDriver")])
