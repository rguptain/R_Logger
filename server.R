library(plumber)

r <- plumb("Log_Analyzer.R")

r$run(port=8000)

# http://localhost:8000/write_log?msg=my%20phone%20number%20is%20123-456-7890&chatID=123