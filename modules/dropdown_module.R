dropdown_ui <- function(id) {
  ns <- NS(id)
  div(class = "four column row",
      div(class = "column", selectInput(ns("shiptype"), "Select ship type", choices = c("Placeholder"))),
      div(class = "column", selectInput(ns("shipname"), "Select ship name", choices = c("Placeholder")))
  )
}

dropdown_server <- function(id, ships) {
  moduleServer(id, function(input, output, session) {
    ship_types <- reactive({sort(as.character(unique(ships$ship_type)))})
    ship_names <- reactive({
      ships %>% 
        filter(ship_type == input$shiptype) %>% 
        pull(SHIPNAME) %>% 
        unique(.) %>%
        sort(.)
    })
    
    observe({updateSelectInput(session, "shiptype", choices = ship_types())})
    observe({updateSelectInput(session, "shipname", choices = ship_names())})
  })
}