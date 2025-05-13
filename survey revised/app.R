# Load necessary libraries
library(shiny)
library(dplyr)
library(readxl)
library(readr)
library(pdftools)
library(googlesheets4)
library(shinyjs)  

# Define helper function
`%||%` <- function(x, y) {
  if (!is.null(x)) x else y
}

# Authenticate with the service account JSON file
gs4_auth(path = "gaf-dataset-057d32fbee1b.json")

# Define your Google Sheet ID
sheet_id <- "1qvX3LVCaC6oeNom2HwdeitoHpk0CG5EP4ZLBEuXEzLI"

# Dynamically create `folder_data_cleaned`
base_dir <- "www/Artifacts for Coding"

# Initialize an empty data frame to store the path breakdown
folder_data <- data.frame(Areas = character(), Semesters = character(), Course = character(), 
                          Assignments = character(), Artifact = character(), FilePath = character(), stringsAsFactors = FALSE)

# Function to recursively navigate through directories and collect path information
get_folder_structure <- function(current_dir, areas = NA, semesters = NA, course = NA, assignments = NA) {
  items <- list.files(current_dir, full.names = TRUE)
  directories <- items[file.info(items)$isdir]
  files <- items[!file.info(items)$isdir]
  
  for (dir in directories) {
    folder_name <- basename(dir)
    if (is.na(areas)) {
      get_folder_structure(dir, areas = folder_name)
    } else if (is.na(semesters)) {
      get_folder_structure(dir, areas = areas, semesters = folder_name)
    } else if (is.na(course)) {
      get_folder_structure(dir, areas = areas, semesters = semesters, course = folder_name)
    } else if (is.na(assignments)) {
      get_folder_structure(dir, areas = areas, semesters = semesters, course = course, assignments = folder_name)
    }
  }
  
  if (!is.na(assignments)) {
    for (file in files) {
      file_name <- basename(file)
      file_path <- file
      folder_data <<- rbind(folder_data, data.frame(areas = areas, semesters = semesters, course = course, 
                                                    assignments = assignments, artifact = file_name, 
                                                    artifact_path = file_path, stringsAsFactors = FALSE))
    }
  }
}

get_folder_structure(base_dir)

# Clean and link instructions with artifacts
folder_data_artifacts <- folder_data %>% 
  filter(!grepl("instructions", artifact, ignore.case = TRUE))

folder_data_instructions <- folder_data %>% 
  filter(grepl("instructions", artifact, ignore.case = TRUE)) %>%
  rename(Instructions = artifact, instructions_path = artifact_path)

folder_data_cleaned <- folder_data_artifacts %>%
  left_join(folder_data_instructions, by = c("areas", "semesters", "course", "assignments"))

# Define a function to get rubric choices based on the selected filter
get_rubric_choices <- function(complete_only = FALSE) {
  rubric_files <- list.files("www/rubrics", pattern = "\\.csv$", full.names = TRUE)
  
  if (complete_only) {
    rubric_files <- Filter(function(file) {
      csv_data <- read_csv(file, show_col_types = FALSE)
      "LO" %in% colnames(csv_data)
    }, rubric_files)
  }
  
  return(rubric_files)
}

# Define UI for application
ui <- fluidPage(
  useShinyjs(),  # Initialize shinyjs
  titlePanel("Graduate Assessment Fellowship Artifact Input"),
  tags$head(
    tags$style(HTML("
      .custom-select {
        max-width: 200px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
      table {
        width: 100%;
        border-collapse: collapse;
      }
      th, td {
        border: 1px solid #ccc;
        padding: 8px;
        text-align: center;
      }
      th {
        background-color: #f2f2f2;
      }
      /* Dark mode styles */
      .dark-mode {
        background-color: #333;
        color: #ccc;
      }
      .dark-mode .custom-select, .dark-mode table, .dark-mode th, .dark-mode td {
        background-color: #444;
        color: #ccc;
        border-color: #555;
      }
      .dark-mode .btn, .dark-mode input, .dark-mode select {
        background-color: #555;
        color: #ccc;
        border: 1px solid #666;
      }
    "))
  ),
  
  # Dark mode toggle button
  checkboxInput("dark_mode", "Dark Mode", value = FALSE),
  
  fluidRow(
    column(10, uiOutput("username_input"))
  ),
  
  fluidRow(
    column(10, uiOutput("password_input"))
  ),
  
  fluidRow(
    column(4, radioButtons("artifact_filter", "Artifact Selection", choices = c("All Artifacts", "Artifacts with Instructions"), inline = TRUE)),
    column(4, radioButtons("rubric_filter", "Rubric Selection", choices = c("All Rubrics", "Complete Rubrics"), inline = TRUE))
  ),
  
  uiOutput("main_content")
)

# Server logic for Shiny app with Google Sheets integration
server <- function(input, output, session) {
  
  # Toggle dark mode
  observe({
    if (input$dark_mode) {
      shinyjs::addClass(selector = "body", class = "dark-mode")
    } else {
      shinyjs::removeClass(selector = "body", class = "dark-mode")
    }
  })
  
  password <- "GAF_tasks"
  user_password <- reactiveVal("")
  responses <- reactiveVal(data.frame())  # Initialize responses as a reactive value
  
  output$password_input <- renderUI({
    fluidRow(
      column(10,
             passwordInput("user_password", "Enter Password:"),
             actionButton("submit_password", "Submit")
      )
    )
  })
  
  observeEvent(input$submit_password, {
    user_password(input$user_password)
    if (user_password() == password) {
      showNotification("Access Granted!", type = "message")
      
      # Observe the artifact filter selection and update the dropdown accordingly
      observe({
        artifacts_to_show <- if (input$artifact_filter == "Artifacts with Instructions") {
          folder_data_cleaned %>% filter(!is.na(instructions_path))
        } else {
          folder_data_cleaned
        }
        
        if (nrow(artifacts_to_show) > 0) {
          updateSelectInput(session, "selected_pdf", 
                            choices = setNames(artifacts_to_show$artifact_path, artifacts_to_show$artifact))
        }
      })
      
      # Observe the rubric filter selection and update the dropdown accordingly
      observe({
        complete_only <- input$rubric_filter == "Complete Rubrics"
        rubric_choices <- get_rubric_choices(complete_only)
        
        if (length(rubric_choices) > 0) {
          updateSelectInput(session, "selected_rubric", 
                            choices = setNames(rubric_choices, basename(rubric_choices)))
        }
      })
      
      output$main_content <- renderUI({
        fluidRow(
          column(4,
                 selectInput("selected_user", "Select User:", 
                             choices = c("Adam", "Chelsea", "User 3", "User 4", "User 5"), 
                             width = "100%", selectize = TRUE),
                 selectInput("selected_pdf", "Select Assignment PDF:", 
                             choices = setNames(folder_data_cleaned$artifact_path, folder_data_cleaned$artifact), 
                             width = "100%", selectize = TRUE),
                 textOutput("pdf_name"),
                 selectInput("selected_rubric", "Select Rubric CSV:", choices = get_rubric_choices(), 
                             width = "100%", selectize = TRUE),
                 textOutput("rubric_name")
          ),
          
          column(8,
                 h4("Instructions Text"),
                 tags$div(style = "height:250px; overflow-y: scroll; border: 1px solid #ccc; padding: 10px;",
                          verbatimTextOutput("instructions_text")
                 ),
                 h4("Assignment Text"),
                 tags$div(style = "height:500px; overflow-y: scroll; border: 1px solid #ccc; padding: 10px;",
                          verbatimTextOutput("pdf_text")
                 ),
                 h4("Rate Learning Outcomes"),
                 uiOutput("rating_inputs"),
                 actionButton("submit", "Submit Responses"),
                 downloadButton("download_csv", "Download Responses")  # Download button for responses
          )
        )
      })
      
      output$instructions_text <- renderText({
        selected_instruction <- folder_data_cleaned %>%
          filter(artifact_path == input$selected_pdf) %>%
          pull(instructions_path)
        
        if (length(selected_instruction) > 0 && file.exists(selected_instruction)) {
          paste(pdf_text(selected_instruction), collapse = "\n")
        } else {
          "Instructions PDF not found."
        }
      })
      
      output$pdf_text <- renderText({
        if (!is.null(input$selected_pdf) && file.exists(input$selected_pdf)) {
          paste(pdf_text(input$selected_pdf), collapse = "\n")
        } else {
          "Assignment PDF not found."
        }
      })
      
      output$rating_inputs <- renderUI({
        if (!is.null(input$selected_rubric)) {
          csv_path <- input$selected_rubric
          csv_data <- read_csv(csv_path)
          if ("LO" %in% names(csv_data)) {
            lo_rows <- csv_data[!is.na(csv_data$LO) & csv_data$LO != "", ]
            
            lo_question_counts <- list()
            
            lapply(1:nrow(lo_rows), function(i) {
              lo_type <- lo_rows$LO[i]
              lo_question_counts[[lo_type]] <- lo_question_counts[[lo_type]] %||% 0
              lo_question_counts[[lo_type]] <- lo_question_counts[[lo_type]] + 1
              
              fluidRow(
                column(12,
                       h5(paste("LO:", lo_type)),
                       h6(paste("Description:", lo_rows$Description[i])),
                       h6(paste("Question Number:", lo_question_counts[[lo_type]])),
                       radioButtons(paste("lo_rating", i, sep="_"), label = "Select Rating:",
                                    choices = c("no answer", NA, 0, 1, 2, 3, 4, 5),
                                    selected = "no answer", inline = TRUE)
                )
              )
            })
          }
        }
      })
      
      observeEvent(input$submit, {
        responses_df <- data.frame(
          rater = character(),
          artifact = character(),
          rubric = character(),
          question = integer(),
          response = integer(),
          lo_type = character(),
          stringsAsFactors = FALSE
        )
        
        if (!is.null(input$selected_rubric)) {
          csv_path <- input$selected_rubric
          csv_data <- read_csv(csv_path)
          lo_rows <- csv_data[!is.na(csv_data$LO) & csv_data$LO != "", ]
          
          lo_question_counts <- list()
          
          for (i in 1:nrow(lo_rows)) {
            lo_type <- lo_rows$LO[i]
            lo_question_counts[[lo_type]] <- lo_question_counts[[lo_type]] %||% 0
            lo_question_counts[[lo_type]] <- lo_question_counts[[lo_type]] + 1
            
            question_number <- lo_question_counts[[lo_type]]
            rating <- input[[paste("lo_rating", i, sep="_")]]
            
            if (!is.null(rating)) {
              new_row <- data.frame(
                rater = input$selected_user,
                artifact = input$selected_pdf,
                rubric = input$selected_rubric,
                lo_type = lo_type,
                question = question_number,
                response = rating,
                stringsAsFactors = FALSE
              )
              
              responses_df <- rbind(responses_df, new_row)
            }
          }
          
          if (nrow(responses_df) > 0) {
            sheet_append(sheet_id, data = responses_df, sheet = "Sheet1")
            showNotification("Responses saved to Google Sheets!", type = "message")
            responses(responses_df)  # Save the responses to the reactive variable for downloading
          } else {
            showNotification("No responses to save. Please complete the ratings.", type = "error")
          }
        }
      })
      
      # Download responses as CSV
      output$download_csv <- downloadHandler(
        filename = function() {
          paste(input$selected_user, input$selected_pdf, "_responses.csv", sep = "_")
        },
        content = function(file) {
          write.csv(responses(), file, row.names = FALSE)
        }
      )
      
    } else {
      showNotification("Access Denied. Try Again.", type = "error")
    }
  })
}

shinyApp(ui = ui, server = server)
