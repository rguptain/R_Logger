library (stringr)
library(RSQLite)
library(httr)
library(rjson)

#* @get /connect_db

ConnectDbChatLogs <- function()
{
  
  db = dbConnect(RSQLite::SQLite(), dbname="ChatLogs.db")
  if(!dbExistsTable(db, "ChatLogs")){
    dbSendQuery(conn=db,
                "CREATE TABLE ChatLogs
                (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                sqltime TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                ChatID TEXT,
                MsgSentBy TEXT,
                Request TEXT,
                Response TEXT,
                IntentName TEXT)
                ")
  }
  return(db)
}  

#* @get /write_log
WriteLog <- function(chatID, MsgSentBy, request, response, intentName)
{
 
  db <- ConnectDbChatLogs()
  
  cur_log <- data.frame(ChatID=chatID, MsgSentBy=MsgSentBy, Request=request, Response=response, IntentName=intentName, stringsAsFactors = FALSE)
  dbWriteTable(conn=db, name="ChatLogs", cur_log, append=T, row.names=F)
  
  data <- dbGetQuery(db, 'SELECT * FROM ChatLogs')

  print(data)
  
  dbDisconnect(db)
}


retrieve_logs <-function()
{
  dst_url <- "https://node-apiai.herokuapp.com/view"
  
  data <- POST(url=dst_url, accept_json(), multipart=FALSE, add_headers("Content-Type" = "application/json", "charset" = "utf-8")) 
  
  resp <- fromJSON(content(data,type="text", encoding = "UTF-8"))

  
  lapply(resp, function(row) 
  {
    chat_id <- row$chat_id
    agent_id <- row$agent_id
    msg <- row$query
    response_received <- row$reply
    intent_name <- row$intent
    
    WriteLog(chat_id, agent_id, msg, response_received, intent_name)
  })

}

read_logs <- function()
{
  db <- ConnectDbChatLogs()
  dbListTables(db)
  dbReadTable(db, "Chatlogs")
  dbGetQuery(db, "SELECT * FROM ChatLogs")
}

empty_logs <- function()
{
  con <- ConnectDbChatLogs()
  dbBegin(con)
  rs <- dbSendStatement(con, "DELETE FROM ChatLogs")
  dbClearResult(rs)
  dbCommit(con)
  dbGetQuery(con, "SELECT count(*) FROM ChatLogs")[1, ]
}


