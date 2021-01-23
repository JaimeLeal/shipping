library(shiny)
library(shiny.semantic)
source("modules/dropdown_module.R")

shinyUI(semanticPage(
  conditionalPanel("!output.load_complete", {
    div(class = "ui one column grid container",
        div(class = "ui active inverted dimmer",
            div(class = "ui text loader", "Loading")))
  }),
  conditionalPanel("output.load_complete", {
    div(class = "ui one column grid container",
        div(class = "row",
            div(class = "ui dividing header", id = "input", "Shipping statistcs")),
        
        div(class = "two column row",
            div(class = "column", 
                tabset(tabs = list(
                  list(menu = "Longest distance", content = leaflet::leafletOutput("map"), id = "first_tab"),
                  list(menu = "Total distance", content = plotly::plotlyOutput("chart"), id = "second_tab")
                ),
                active = "first_tab")     
            ),
            div(class = "column", 
                div(class = "ui card", 
                    div(class = "content",
                        div(class = "header", "Ship information")),
                    div(class = "content",
                        htmlOutput("card_content")),
                    div(class = "ui teal statistic",
                        div(class = "value", textOutput("distance")),
                        div(class = "label", "Longest distance sailed (m)")))
            )
        ),
        dropdown_ui("mod1")
    )
  })
)
)
