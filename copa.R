library(broom)

sql <- "SELECT
TO_Number(\"Customer\") as \"CustomerNumber\",
\"CustomerText\",
\"BillingDocumentNo\",
\"COPA_Doc_Creation_Date\",
\"VV998QPhysicalCases\",
\"TotalGrossRevenue\",
\"TotalDiscountsAndAllowances\"
  FROM \"cona-reporting.profitability::Q_CA_S_CopaPowerView\" (
  'PLACEHOLDER' = ('$$IP_Controlling_Area$$', 'US06'),
  'PLACEHOLDER' = ('$$IP_Data_Source$$', '''ALL''') ) \"cona-reporting.profitability::Q_CA_S_CopaPowerView\" WHERE
\"BillingDate\" >= ? AND
\"BillingDate\" < ?"

param1 <- gsub("-", "", Sys.Date() - 1 - months(6))
param2 <- gsub("-", "", Sys.Date())

copa <- dbGetQuery(jdbcConnection, sql, param1, param2)

# invoice counts last 3 and 6 months

inv3 <- copa %>%
  filter(COPA_Doc_Creation_Date < gsub("-", "", Sys.Date() - 1 - months(3))) %>%
  select(CustomerNumber, BillingDocumentNo) %>%
  unique() %>%
  count(CustomerNumber, name = "l3_invcnt")

inv6 <- copa %>%
  select(CustomerNumber, BillingDocumentNo) %>%
  unique() %>%
  count(CustomerNumber, name = "l6_invcnt")

# frequency of customer in the feature period

feature_freq <- copa %>%
  select(CustomerNumber, COPA_Doc_Creation_Date) %>%
  unique() %>%
  count(CustomerNumber, name = "feature_freq")

# gap since last invoice

Ft_dt_gap_base <- copa %>%
  select(CustomerNumber, COPA_Doc_Creation_Date) %>%
  unique() %>%
  mutate(COPA_Doc_Creation_Date = as.Date(COPA_Doc_Creation_Date, "%Y%m%d")) %>%
  mutate(feature_date = Sys.Date() - 1,
         days = feature_date - COPA_Doc_Creation_Date)

Ft_dt_gap_oldest <- Ft_dt_gap_base %>%
  group_by(CustomerNumber) %>%
  filter(days == max(days)) %>%
  ungroup() %>%
  rename(Feature_period_gap = days) %>%
  select(CustomerNumber, Feature_period_gap)

Ft_dt_gap_recent <- Ft_dt_gap_base %>%
  group_by(CustomerNumber) %>%
  filter(days == min(days)) %>%
  ungroup() %>%
  rename(Ft_dt_gap = days)%>%
  select(CustomerNumber, Ft_dt_gap)

# revenue and qty last 3 and 6 months

rev.qty6 <- copa %>%
  group_by(CustomerNumber) %>%
  summarise_at(c("VV998QPhysicalCases", "TotalGrossRevenue"), mean, na.rm = F) %>%
  rename(qty_l6 = VV998QPhysicalCases,
         netwr_l6 = TotalGrossRevenue)

rev.qty3 <- copa %>%
  filter(COPA_Doc_Creation_Date < gsub("-", "", Sys.Date() - 1 - months(3))) %>%
  group_by(CustomerNumber) %>%
  summarise_at(c("VV998QPhysicalCases", "TotalGrossRevenue"), mean, na.rm = F) %>%
  rename(qty_l3 = VV998QPhysicalCases,
         netwr_l3 = TotalGrossRevenue)

# revenue and qty trend strength

rev.qty.trend <- copa %>%
  group_by(CustomerNumber, COPA_Doc_Creation_Date) %>%
  summarise_at(c("VV998QPhysicalCases", "TotalGrossRevenue"), mean, na.rm = F) %>%
  arrange(CustomerNumber, COPA_Doc_Creation_Date)

rev.trend <- rev.qty.trend %>%
  group_by(CustomerNumber) %>%
  do(tidy(lm(TotalGrossRevenue ~ as.numeric(COPA_Doc_Creation_Date), data = .))) %>%
  filter(term == "as.numeric(COPA_Doc_Creation_Date)") %>%
  select(-c(term, std.error, statistic, p.value)) %>%
  rename(netwr_trend_strength = estimate)

qty.trend <- rev.qty.trend %>%
  group_by(CustomerNumber) %>%
  do(tidy(lm(VV998QPhysicalCases ~ as.numeric(COPA_Doc_Creation_Date), data = .))) %>%
  filter(term == "as.numeric(COPA_Doc_Creation_Date)") %>%
  select(-c(term, std.error, statistic, p.value)) %>%
  rename(qty_trend_strength = estimate)

# discount average

weighted_avg_discount_last_six_months <- copa %>%
  group_by(CustomerNumber) %>%
  summarise(weighted_avg_discount_last_six_months = mean(TotalDiscountsAndAllowances))

# tie in

df <- mast.cust %>%
  left_join(inv3, by = "CustomerNumber") %>%
  left_join(inv6, by = "CustomerNumber") %>%
  left_join(feature_freq, by = "CustomerNumber") %>%
  left_join(Ft_dt_gap_recent, by = "CustomerNumber") %>%
  left_join(Ft_dt_gap_oldest, by = "CustomerNumber") %>%
  left_join(rev.qty3, "CustomerNumber") %>%
  left_join(rev.qty6, by = "CustomerNumber") %>%
  left_join(rev.trend, by = "CustomerNumber") %>%
  left_join(qty.trend, by = "CustomerNumber") %>%
  left_join(weighted_avg_discount_last_six_months, by = "CustomerNumber")

# negatives

cs_qty_l6_neg <- copa %>%
  filter(VV998QPhysicalCases < 0) %>%
  group_by(CustomerNumber) %>%
  summarise(cs_qty_l6_neg = sum(VV998QPhysicalCases))

netwr_l6_neg <- copa %>%
  filter(TotalGrossRevenue < 0) %>%
  group_by(CustomerNumber) %>%
  summarise(netwr_l6_neg = sum(TotalGrossRevenue))

# negative by positive ratios

cs_qty_l6_n_p_ratio <- (copa %>%
                          filter(VV998QPhysicalCases < 0) %>%
                          group_by(CustomerNumber) %>%
                          summarise(neg = sum(VV998QPhysicalCases))) %>%
  left_join(copa %>%
              filter(VV998QPhysicalCases > 0) %>%
              group_by(CustomerNumber) %>%
              summarise(pos = sum(VV998QPhysicalCases))) %>%
  mutate(cs_qty_l6_n_p_ratio = neg / pos) %>%
  select(-c(neg, pos))

netwr_l6_n_p_ratio <- (copa %>%
                         filter(TotalGrossRevenue < 0) %>%
                         group_by(CustomerNumber) %>%
                         summarise(neg = sum(TotalGrossRevenue))) %>%
  left_join(copa %>%
              filter(TotalGrossRevenue > 0) %>%
              group_by(CustomerNumber) %>%
              summarise(pos = sum(TotalGrossRevenue))) %>%
  mutate(cs_qty_l6_n_p_ratio = neg / pos) %>%
  select(-c(neg, pos))

df <- df %>%
  left_join(cs_qty_l6_neg, by = "CustomerNumber") %>%
  left_join(netwr_l6_neg, by = "CustomerNumber") %>%
  left_join(cs_qty_l6_n_p_ratio, by = "CustomerNumber") %>%
  left_join(netwr_l6_n_p_ratio, by = "CustomerNumber")

rm(list=ls()[! ls() %in% c("df","jdbcConnection", "jdbcDriver")])
