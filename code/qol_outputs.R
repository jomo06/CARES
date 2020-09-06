### to be run after ppp_data_marge_0808.R
### john@mccambridge.co

### create outputs of one enhanced CSV per state -------------------------------

# by(adbs, adbs$State, FUN=function(i) write.csv(i, paste0("PPP Loans 0808 Enhanced ",i$State[1], ".csv")))

adbs %>%
    group_by(State) %>%
    group_walk(~ write_csv(.x, file.path("data/adbs_bystate", paste0("PPP Loans 0808 Enhanced ", .y$State, ".csv"))))
  
  
### create outputs per state of businesses with shared addresses ---------------

sharedaddress_bystate <- adbs %>% filter(!is.na(Address)) %>%
  group_by(State, Address) %>%
  summarise(SumLoanRangeMin = sum(LoanRangeMin),
            LoanCount = n()
            ) %>% filter(LoanCount > 1)

