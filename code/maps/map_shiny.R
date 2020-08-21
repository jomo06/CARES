# prepare input data
#source("code/maps/map_prep.R")

library(shiny)
library(leaflet)
library(leaflet.extras)
library(rgeos)

ui <- fluidPage(
    titlePanel("PPP Loans + Census Data Explorer"),
    sidebarLayout(
        sidebarPanel(
            selectInput(inputId = "geoLevel",
                        label = "Select Geographic Level:",
                        choices = c("State" = "State", 
                                    "County" = "County",
                                    "Congressional District" = "Congressional District"),
                        selected = "state_geoid"),
            selectInput(inputId = "demographicVariable",
                        label = "Select Demographic Variable:",
                        choices = c("Total Population" = "total_population", 
                                    "Per Capita Income" = "inc_percapita_income", 
                                    "Percent Poverty" = "inc_pct_poverty",
                                    "Percent Non-White" = "race_pct_nonwhite",
                                    "Percent Speaking Another Language" = "any_other_than_english_pct"),
                        selected = "total_population"),
            selectInput(inputId = "loanVariable",
                        label = "Select PPP Loan Statistic:",
                        choices = c("Estimate Loan Amount - All Loans" = "LoanAmt_Est_All", 
                                    "Estimate Loan Amount - Up to 150K" = "LoanAmt_Est_lt150k",
                                    "Number of Loans - All Loans" = "LoanCnt_All",
                                    "Number of Loans - Up to 150K" = "LoanCnt_lt150k",
                                    "Number of Loans - More than 150K" = "LoanCnt_gt150k"),
                        selected = "LoanAmt_Est_All")
            
        ),
        mainPanel(
            leafletOutput("mymap")
            #textOutput("selected_var")
        )
    )
)

server <- function(input, output, session) {
    
    # output$selected_var <- renderText({ 
    #     paste(c(input$geoLevel, input$demographicVariable, input$loanVariable))
    # })
    
    output$mymap <- renderLeaflet({
        
        df <- adbs_all_geos %>% 
            filter(GEOID_TYPE == input$geoLevel) %>% 
            select(GEOID,
                   "demoVar" = input$demographicVariable,
                   "loanVar" = input$loanVariable)
        
        if (input$geoLevel == "County") {
            spdf <- merge(counties, df, by = "GEOID")
        } else if (input$geoLevel == "State") {
            spdf <- merge(states, df, by = "GEOID")
        } else if (input$geoLevel == "Congressional District") {
            spdf <- merge(cds, df, by = "GEOID")
        }
        
        leaflet(data = spdf) %>% 
            addProviderTiles(providers$Stamen.TonerLite) %>% 
            addPolygons(fillColor = ~colorQuantile("YlOrRd", demoVar)(demoVar), 
                        color = "#444444", 
                        weight = 1, 
                        fillOpacity = 0.8) %>% 
            addCircles(~as.numeric(INTPTLON), ~as.numeric(INTPTLAT), 
                       radius = ~sqrt(loanVar),
                       color = "#444444", 
                       weight = 1, 
                       fillOpacity = 0.2)
    })
}

shinyApp(ui, server)


