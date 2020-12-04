library(tidyverse)
library(RJDBC)
library(keyring)

options(java.parameters = "-Xmx8048m")
memory.limit(size=10000000000024)

classPath="C:/Program Files/sap/hdbclient/ngdbc.jar"
# For ngdbc.jar use        # jdbcDriver <- JDBC(driverClass="com.sap.db.jdbc.Driver",
# For HANA Studio jar use  # jdbcDriver <- JDBC(driverClass="com.sap.ndb.studio.jdbc.JDBCConnection",

jdbcDriver <- JDBC(driverClass="com.sap.db.jdbc.Driver",
                   classPath="C:/Program Files/sap/hdbclient/ngdbc.jar")

jdbcConnection <- dbConnect(jdbcDriver,
                            "jdbc:sap://vlpbid001.cokeonena.com:30015/_SYS_BIC",
                            "fl014036",
                            key_get("hana.pw"))
