

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

# write.csv(df, "data.csv", row.names = FALSE)

rm(jdbcConnection, jdbcDriver)
