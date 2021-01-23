library(shiny)
library(shiny.semantic)
library(geosphere)
library(leaflet)
library(data.table)
library(dplyr)
source("utils.R")
source("modules/dropdown_module.R")

shinyServer(function(input, output, session) {
  
  output$load_complete <- renderText(FALSE)
  
  withProgress({
    # Read data
    ships <- data.table::fread("ships.csv", sep = ",")
    output$load_complete <- renderText(TRUE)
  }, message = "Loading data", value = 0.5)
  
  # Variable to hide/show content
  outputOptions(output, "load_complete", suspendWhenHidden = FALSE)
  
  # Inputs
  dropdown_server("mod1", ships)
  
  # Calculate longest distance by ship
  ship_statistics <- reactive({
    withProgress({
      ship_distance <- ships[SHIPNAME == input$"mod1-shipname"][order(DATETIME)]
      ship_distance <- ship_distance[, `:=`(
        LAT_prev = data.table::shift(LAT, n = 1, type = "lag"),
        LON_prev = data.table::shift(LON, n = 1, type = "lag"),
        DATETIME_prev = data.table::shift(DATETIME, n = 1, type = "lag"))]
      # Calculate distance between observations
      ship_distance <- ship_distance[, DISTANCE := dt_haversine(LAT_prev, LON_prev, LAT, LON)]
      total_distance <- ship_distance[, .(total_distance = sum(DISTANCE, na.rm = TRUE)),
                                      by = "date"]
      
      # Select observation with longest distance
      longest_distance <- ship_distance[order(-DISTANCE, -DATETIME), .SD[1]]
      # Add labels for Leaflet
      longest_distance <- longest_distance %>%
        mutate(LABEL = HTML(glue::glue("Ship Name: {SHIPNAME} <br>
                                 Lat: {LAT} <br>
                                 Lon: {LON}) <br>
                                 Date: {DATETIME}"))) %>%
        mutate(LABEL_prev = HTML(glue::glue("Ship Name: {SHIPNAME} <br>
                                 Lat: {LAT_prev} <br>
                                 Lon: {LON_prev}) <br>
                                 Date: {DATETIME_prev}")))
      list(longest_distance, total_distance)
    }, message = "Processing ...")
  })
  
  # Map
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>%
      addCircleMarkers(data = ship_statistics()[[1]], 
                       lat = ~LAT,
                       lng = ~ LON, 
                       label  =  ~LABEL,
                       stroke = FALSE, 
                       fillOpacity = 0.5,
                       color = "green",
                       clusterOptions = markerClusterOptions()
      ) %>%
      addCircleMarkers(data = ship_statistics()[[1]], 
                       lat = ~LAT_prev,
                       lng = ~ LON_prev, 
                       label  =  ~LABEL_prev,
                       stroke = FALSE, 
                       fillOpacity = 0.5,
                       color =  "red",
                       clusterOptions = markerClusterOptions()
      )
  })
  
  # Card content
  output$card_content <-  renderText(
    ship_statistics()[[1]] %>% 
      mutate(card_content = glue::glue(
        "Ship name: {SHIPNAME} <br>
        ID: {SHIP_ID} <br>
        Flag: {FLAG} <i class='{tolower(FLAG)} flag'></i> <br>
        Ship type: {ship_type} <br>
        Lat: {LAT} <br>
        Lon: {LON}) <br>
        Date: {date}")) %>% 
      pull(card_content)
  )
  
  # Statistic
  output$distance <- renderText(round(ship_statistics()[[1]]$DISTANCE, 1))
  
  # Graph
  output$chart <- plotly::renderPlotly({
    fig <- ship_statistics()[[2]] %>% 
      plotly::plot_ly(x = ~date, y = ~total_distance / 1000, type = "bar", color = I("#008080")) %>% 
      plotly::layout(title = "Total distance traveled",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Total ditance (km)"))
  })
})
