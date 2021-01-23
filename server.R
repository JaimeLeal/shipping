library(shiny.semantic)
library(geosphere)
library(leaflet)
library(data.table)
source("utils.R")

shinyServer(function(input, output, session) {
  
  withProgress({
    # Read data
    ships <- data.table::fread("ships.csv", sep = ",")
    ships <- ships[order(SHIP_ID, DATETIME)]
    # Calculate distance between observations
    ships <- ships[, `:=`(
      LAT_prev = data.table::shift(LAT, n = 1, type = "lag"),
      LON_prev = data.table::shift(LON, n = 1, type = "lag"),
      DATETIME_prev = data.table::shift(DATETIME, n = 1, type = "lag")),
      by = "SHIP_ID"]
    ships <- ships[,DISTANCE := dt_haversine(LAT_prev, LON_prev, LAT, LON)]
    # Select observation with longest distance
    ships_longest_dist <- ships[order(-DISTANCE, -DATETIME), .SD[1], by = "SHIP_ID"]
  }, message = "Loading data")
  
  # Inputs
  ship_types <- reactive({
    sort(as.character(unique(ships$ship_type)))
  })
  
  ship_names <- reactive({
    ships_longest_dist %>% 
      filter(ship_type == input$shiptype) %>% 
      pull(SHIPNAME) %>%
      sort(.)
  })
  
  observe({
    updateSelectInput(session, "shiptype", choices = ship_types())
  })
  
  observe({
    updateSelectInput(session, "shipname", choices = ship_names())
  })
  
  
  selected_ship <- reactive({
    ships_longest_dist %>% 
      filter(SHIPNAME == input$shipname) %>%
      mutate(LABEL = HTML(glue::glue("Ship Name: {SHIPNAME} <br>
                                 Lat: {LAT} <br>
                                 Lon:{LON}) <br>
                                 Date: {DATETIME}"))) %>%
      mutate(LABEL_prev = HTML(glue::glue("Ship Name: {SHIPNAME} <br>
                                 Lat: {LAT_prev} <br>
                                 Lon:{LON_prev}) <br>
                                 Date: {DATETIME_prev}")))
  })
  
  # Map
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>%
      addCircleMarkers(data = selected_ship(), 
                       lat = ~LAT,
                       lng = ~ LON, 
                       label  =  ~LABEL,
                       stroke = FALSE, 
                       fillOpacity = 0.5,
                       color = "green",
                       clusterOptions = markerClusterOptions()
      ) %>%
      addCircleMarkers(data = selected_ship(), 
                       lat = ~LAT_prev,
                       lng = ~ LON_prev, 
                       label  =  ~LABEL_prev,
                       stroke = FALSE, 
                       fillOpacity = 0.5,
                       color =  "red",
                       clusterOptions = markerClusterOptions()
      )
  })
  
  # Text output
  
  output$card_content <-  renderText(
    selected_ship() %>% 
      mutate(card_content = glue::glue(
        "Ship Name: {SHIPNAME} <br>
        Lat: {LAT} <br>
        Lon:{LON}) <br>
        Date: {DATETIME}")) %>% 
      pull(card_content) %>% print(.)
  )
  # Statistic
  output$distance <- renderText(round(selected_ship()$DISTANCE, 1))
  
  
})
