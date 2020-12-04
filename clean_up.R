df <- do.call(data.frame,
               lapply(df,
                      function(x) replace(x, is.infinite(x), NA)))

colnames(df)[colSums(is.na(df)) > 0]

df <- df %>%
  mutate(Location = as.character(Location)) %>%
  replace_na(list(avg_partial_del_l6 = 0,
                  partial_delivery_count_per_ord_l6 = 0,
                  visit_count_last_six_months = 0,
                  visit_count_last_six_months_per_invoice_rn = 0,
                  visit_count_last_three_months = 0,
                  visit_count_last_three_months_per_invoice_rn = 0,
                  mean_resol_days_l6_rn = 0,
                  cs_qty_l6_neg = 0,
                  netwr_l6_neg = 0,
                  disp_count_last_six_per_invoice = 0,
                  disp_l6_pi_cat_High_dispute_l6 = 0,
                  disp_l6_pi_cat_Low_dispute_l6 = 0,
                  disp_l6_pi_cat_No_dispute_l6 = 0,
                  Location = "undefined"))

colnames(df)[colSums(is.na(df)) > 0]
