sql <- "SELECT TOP 10 * FROM \"cona-mdm::Q_CA_R_EquipmentMasterWithCustomer\"
        WHERE (1 <> 0)"

equip <- dbGetQuery(jdbcConnection, sql)
