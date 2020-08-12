#################################
# NOTE: run map_prep.R first to create the input datasets county_demo and ppp_census
#################################

library(shiny)
library(leaflet)
library(leaflet.extras)

ui <- fluidPage(
    titlePanel("Michigan PPP Loans"),
    sidebarLayout(
        sidebarPanel(
            selectInput(inputId = "geoLevel",
                        label = "Select Geographic Level:",
                        choices = c("State" = "state_geoid", 
                                    "County" = "county_geoid", 
                                    "Congressional District" = "cd_geoid",
                                    "Census Tract" = "tract_geoid",
                                    "ZCTA" = "zcta_geoid"),
                        selected = "county_geoid"),
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
                        choices = c("Total Amt (Low Estimate)" = "Low", 
                                    "Total Amt (Med Estimate)" = "Mid", 
                                    "Total Amt (High Estimate)" = "High",
                                    "Per Capita Amt (Low Estimate)" = "LowPerCap", 
                                    "Per Capita Amt (Med Estimate)" = "MidPerCap", 
                                    "Per Capita Amt (High Estimate)" = "HighPerCap"),
                        selected = "Mid")
            
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
        
        demo <- county_demo %>% 
            select(GEOID, "demoVar" = input$demographicVariable)
            #select(GEOID, "demoVar" = "total_population")
        
        dat <- ppp_census %>%
            select("GEOID" = "county_geoid", 
                   "sumVar" = input$loanVariable) %>% 
                   #"sumVar" = "Mid") %>% 
            group_by(GEOID) %>%
            summarize(val = sum(sumVar, na.rm = TRUE)) %>%
            left_join(demo, by = "GEOID")
        
        spdf <- merge(counties_shp, dat, by = "GEOID")
        
        leaflet(data = spdf) %>% 
            addProviderTiles(providers$Stamen.TonerLite) %>% 
            addPolygons(fillColor = ~colorQuantile("YlOrRd", demoVar)(demoVar), 
                        color = "#444444", 
                        weight = 1, 
                        fillOpacity = 0.8) %>% 
            addCircles(~as.numeric(INTPTLON), ~as.numeric(INTPTLAT), 
                       radius = ~sqrt(val),
                       color = "#444444", 
                       weight = 1, 
                       fillOpacity = 0.2)
    })
}

shinyApp(ui, server)


