sql <- "SELECT
  \"SoldTo\",
  \"ResponseTimeinHours\"
  FROM \"cona-reporting.cam::Q_CA_R_PerformanceReactive\" (
  'PLACEHOLDER' = ('$$IP_SalesOrganization$$', '''4500'''),
  'PLACEHOLDER' = ('$$IP_NotificationDateFrom$$', '2020-04-14'),
  'PLACEHOLDER' = ('$$IP_NotificationDateTo$$', '2020-10-14'),
  'PLACEHOLDER' = ('$$IP_IncludeUserStatus$$', '''ALL'''),
  'PLACEHOLDER' = ('$$IP_ExcludeUserStatus$$', '''NONE'''),
  'PLACEHOLDER' = ('$$IP_IncludeSystemStatus$$', '''ALL'''),
  'PLACEHOLDER' = ('$$IP_ExcludeSystemStatus$$', '''NONE'''),
  'PLACEHOLDER' = ('$$IP_IncludeOrderUserStatus$$', '''ALL'''),
  'PLACEHOLDER' = ('$$IP_ExcludeOrderUserStatus$$', '''NONE'''),
  'PLACEHOLDER' = ('$$IP_IncludeOrderSystemStatus$$', '''ALL'''),
  'PLACEHOLDER' = ('$$IP_ExcludeOrderSystemStatus$$', '''NONE''') ) \"cona-reporting.cam::Q_CA_R_PerformanceReactive\" WHERE
\"Plant\" >= ? AND
\"Plant\" <= ? AND
\"CompletedOrders\" = ? AND
\"DistributionChannel\" != ? AND
\"DistributionChannelText\" != ? AND
\"MaintenancePlannerGroup\" = ? AND
\"OrderType\" = ? AND
\"NotificationType\" = ? AND
\"NotificationUserStatus\" != ?"

param1 <- "I000"
param2 <- "I023"
param3 <- "1"
param4 <- "Z3"
param5 <- "Full Service Vending"
param6 <- "ZPD"
param7 <- "ZC02"
param8 <- "Z2"
param9 <- "CANC"

repairtime <- dbGetQuery(jdbcConnection, sql, param1, param2, param3, param4, param5, param6, param7, param8, param9)

repairtime <- repairtime %>%
  mutate(CustomerNumber = as.numeric(SoldTo)) %>%
  select(-c(SoldTo)) %>%
  group_by(CustomerNumber) %>%
  summarise(mean_resol_days_l6_rn = mean(ResponseTimeinHours))

df <- df %>%
  left_join(repairtime, by = "CustomerNumber")

rm(list=ls()[! ls() %in% c("df","jdbcConnection", "jdbcDriver")])
