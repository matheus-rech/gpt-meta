library(plumber)
library(jsonlite)

#* @filter cors
cors <- function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE")
    res$setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type")
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }
}

#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-", 
      req$REQUEST_METHOD, req$PATH_INFO, "-", 
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
  plumber::forward()
}

#* @filter auth
function(req, res) {
  api_key <- Sys.getenv("R_SERVICE_API_KEY")
  auth_header <- req$HTTP_AUTHORIZATION
  
  if (is.null(auth_header) || !grepl("^Bearer ", auth_header)) {
    res$status <- 401
    return(list(error = "Unauthorized"))
  }
  
  token <- sub("^Bearer ", "", auth_header)
  
  if (token != api_key) {
    res$status <- 401
    return(list(error = "Invalid API key"))
  }
  
  plumber::forward()
}

validate_r_code <- function(code) {
  # Basic input validation
  if (!is.character(code) || length(code) == 0) {
    return(FALSE)
  }
  
  # Check for potentially dangerous functions
  dangerous_functions <- c('system', 'shell', 'exec', 'eval')
  for (func in dangerous_functions) {
    if (grepl(paste0(func, '\\('), code)) {
      return(FALSE)
    }
  }
  
  return(TRUE)
}

#* Execute R code
#* @param code The R code to execute
#* @post /execute
function(code) {
  if (!validate_r_code(code)) {
    return(list(error = "Invalid or potentially unsafe R code"))
  }

  tryCatch({
    # Execute the code in a safe environment
    safe_env <- new.env(parent = baseenv())
    result <- eval(parse(text = code), envir = safe_env)
    
    # Convert the result to JSON
    json_result <- toJSON(result, auto_unbox = TRUE, pretty = TRUE)
    
    return(list(result = json_result))
  }, error = function(e) {
    return(list(error = as.character(e)))
  })
}

# Run the API
pr <- plumber::plumb("r_service.R")
pr$run(host = "0.0.0.0", port = as.numeric(Sys.getenv("PORT")))
