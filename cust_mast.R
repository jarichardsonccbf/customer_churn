sql <- 'SELECT \"CustomerNumber\",
               \"Name1\",
               \"TradeChannel\",
               \"TradeChannelText\",
               \"SalesOffice\",
               \"ShippingConditionsDescription\",
               \"CustSubTradeChlDesc\",
               \"Tradename\"
         FROM \"cona-mdm::Q_CA_R_MDM_Customer_GeneralSalesArea\"'

mast.cust <- dbGetQuery(jdbcConnection, sql)


mast.cust <- mast.cust %>%
  mutate(CustomerNumber = as.numeric(CustomerNumber)) %>%
  left_join(data.frame(Location = c("Tampa",
                                    "Orlando",
                                    "Jacksonville",
                                    "Lakeland",
                                    "Sarasota",
                                    "Ft Myers",
                                    "Ft Pierce",
                                    "Daytona",
                                    "Gainesville",
                                    "Brevard",
                                    "Broward",
                                    "Palm Beach",
                                    "Miami Dade",
                                    "The Keys"),
                       SalesOffice = c("I000",
                                       "I001",
                                       "I002",
                                       "I004",
                                       "I005",
                                       "I006",
                                       "I007",
                                       "I010",
                                       "I012",
                                       "I013",
                                       "I017",
                                       "I018",
                                       "I019",
                                       "I020")), by = "SalesOffice") %>%
  filter(ShippingConditionsDescription != "Employee Sales")
