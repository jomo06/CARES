## open issues ##
# edit color legend to display numeric ranges for color quantiles
# add legend for circle sizes
# add mouseover annotations
# fix default zoom level
# add scatterplot
# add data table
# edit UI so that map takes up full screen


# prepare input data
#source("code/maps/map_prep.R")

library(shiny)
library(leaflet)
library(leaflet.extras)
library(rgeos)

# get list of state fips
state_ls <- state_fips$state_fips[state_fips$state_fips %in% adbs_state$GEOID]
names(state_ls) <- state_fips$state_name[state_fips$state_fips %in% adbs_state$GEOID]
state_ls <- sort(state_ls)

ui <- fluidPage(
    titlePanel("PPP Loans + Census Data Explorer"),
    sidebarLayout(
        sidebarPanel(
            radioButtons("mapType", "Map Type", choices = c("All U.S.", "By State")),
            
            conditionalPanel(condition = "input.mapType == 'By State'",
                             selectInput("stateFilter", "State", choices = state_ls),
                             selectInput("geoLevel", "Within State Geography",
                                         choices = c("County", "Congressional District"))),
            
            selectInput("demoVar", "Demographic Variable",
                        choices = c("Total Population" = "total_population", 
                                    "Per Capita Income" = "inc_percapita_income", 
                                    "Percent Poverty" = "inc_pct_poverty",
                                    "Percent Non-White" = "race_pct_nonwhite",
                                    "Percent Speaking Another Language" = "any_other_than_english_pct")),
            
            selectInput("loanVar", "Loan Variable",
                        choices = c("Total Loan Amount - Minimum Estimate" = "Low", 
                                    "Total Loan Amount - Midpoint Estimate" = "Mid",
                                    "Total Loan Amount - Maximum Estimate" = "High",
                                    "Per Capita Loan Amount - Minimum Estimate" = "LowPerCap", 
                                    "Per Capita Loan Amount - Midpoint Estimate" = "MidPerCap",
                                    "Per Capita Loan Amount - Maximum Estimate" = "HighPerCap")),
            
            conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                             tags$div("Loading map...",id="loadmessage"))
        
        ),
        mainPanel(
            leafletOutput("mymap")
            #textOutput("selected_var")
        )
    )
)


server <- function(input, output, session) {
    
    output$mymap <- renderLeaflet({
        
        if (input$mapType == "All U.S.") {
            
            df <- adbs_all_geos %>% 
                filter(GEOID_TYPE == "State") %>% 
                select(GEOID,
                       "demoVar" = input$demoVar,
                       "loanVar" = input$loanVar)
            
            spdf <- merge(states, df, by = "GEOID", all.x = FALSE)
            
        } else {
            
            df <- adbs_all_geos %>% 
                filter(str_sub(GEOID,1,2) %in% input$stateFilter) %>%  # add "state" column to dataset
                select(GEOID,
                       "demoVar" = input$demoVar,
                       "loanVar" = input$loanVar)
            
            if (input$geoLevel == "County") {
                spdf <- merge(counties, df, by = "GEOID", all.x = FALSE)
            } else if (input$geoLevel == "Congressional District") {
                spdf <- merge(cds, df, by = "GEOID", all.x = FALSE)
            }
            
        }       
        
        pal = colorQuantile("YlOrRd", spdf$demoVar)
        
        leaflet(data = spdf) %>% 
            addProviderTiles(providers$Stamen.TonerLite) %>% 
            addPolygons(fillColor = ~pal(demoVar), 
                        color = "#444444", 
                        weight = 1, 
                        fillOpacity = 0.8) %>% 
            addCircles(~as.numeric(INTPTLON), ~as.numeric(INTPTLAT), 
                       radius = ~sqrt(loanVar),
                       color = "#444444", 
                       weight = 1, 
                       fillOpacity = 0.2) %>% 
            addLegend(pal = pal, values = ~demoVar,
                      title = input$demoVar, # edit legend to include numeric range for each quantile instead of quantile labels
                      #labFormat = labelFormat(prefix = "$"),
                      opacity = 0.8)
        
    })
    
}

shinyApp(ui, server)


