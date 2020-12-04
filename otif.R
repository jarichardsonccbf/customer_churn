sql <- "SELECT
\"SoldTo\",
\"CaseFillPerc\"
  FROM \"cona-reporting.delivery-execution::Q_CA_S_DeliveryExecutionOTIF\" (
  'PLACEHOLDER' = ('$$IP_KeyDate$$', '2020-09-10') ) \"cona-reporting.delivery-execution::Q_CA_S_DeliveryExecutionOTIF\" WHERE
\"AccountGroup\" = ? and
\"ActualDeliveryDate\" > ?"

param1 <- "Z001"
param2 <- "20200301"

otif <- dbGetQuery(jdbcConnection, sql, param1, param2)

avg_partial_del_l6 <- otif %>%
  mutate(CaseFillPerc = ifelse(CaseFillPerc < 100, 0, 100)) %>%
  group_by(SoldTo) %>%
  summarize(avg_partial_del_l6 = length(CaseFillPerc[CaseFillPerc == "0"])/n() * 100) %>%
  mutate(CustomerNumber = as.numeric(SoldTo)) %>%
  select(-c(SoldTo))

partial_delivery_count_per_ord_l6 <- otif %>%
  mutate(CaseFillPerc = ifelse(CaseFillPerc < 100, 0, 100)) %>%
  group_by(SoldTo) %>%
  summarize(partial_delivery_count_per_ord_l6 = length(CaseFillPerc[CaseFillPerc == "0"])) %>%
  mutate(CustomerNumber = as.numeric(SoldTo)) %>%
  select(-c(SoldTo))

df <- df %>%
  left_join(avg_partial_del_l6, by = "CustomerNumber") %>%
  left_join(partial_delivery_count_per_ord_l6, by = "CustomerNumber") %>%
  mutate(partial_delivery_count_per_ord_l6 = partial_delivery_count_per_ord_l6 / l6_invcnt)

rm(list=ls()[! ls() %in% c("df","jdbcConnection", "jdbcDriver")])
