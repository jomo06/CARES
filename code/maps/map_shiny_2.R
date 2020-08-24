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
            radioButtons("geoScope", "Map Type", choices = c("All U.S.", "By State")),
            conditionalPanel(condition = "input.geoScope == 'By State'",
                             selectInput("stateFilter", "State", choices = state_ls))
        ),
        mainPanel()
    )
)

server <- function(input, output, session) {
    
}

shinyApp(ui, server)


