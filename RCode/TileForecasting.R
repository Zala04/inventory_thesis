library(dplyr)
library(forecast)
library(DBI)
library(RPostgres)
library(dotenv)


forecastFunc <- function(y, stock) {
  horizon <- 65
  train <- y[1:300]
  test  <- y[301:365]

  train_series <- ts(train, frequency = 7)
  test_vectorValues  <- as.numeric(test)

  model_arima  <- auto.arima(train_series)
  model_ets    <- ets(train_series)
  model_snaive <- snaive(train_series, h = 65)

  forecast_arima <- forecast(model_arima, h = 65)
  forecast_ets   <- forecast(model_ets, h = 65)
  forecast_snaive <- snaive(train_series, h = 65)

  rmse_arima   <- accuracy(forecast_arima, test_vectorValues)[2, "RMSE"]
  rmse_ets     <- accuracy(forecast_ets, test_vectorValues)[2, "RMSE"]
  rmse_snaive  <- accuracy(forecast_snaive, test_vectorValues)[2, "RMSE"]

  model_scores <- data.frame(
    model = c("ARIMA", "ETS", "SNAIVE"),
    RMSE  = c(rmse_arima, rmse_ets, rmse_snaive)
  )
  best_model <- model_scores$model[which.min(model_scores$RMSE)]

  full_s <- ts(y, frequency = 7)

  # refit best model on full data
  if (best_model == "ARIMA") {
    modFinal <- auto.arima(full_s)
    final_forecast <- forecast(modFinal, h = horizon)
  } else if (best_model == "ETS") {
    modFinal <- ets(full_s)
    final_forecast <- forecast(modFinal, h = horizon)
  } else {
    final_forecast <- snaive(full_s, h = horizon)
  }

  predicted_sales <- pmax(round(as.numeric(final_forecast$mean)), 0)
  # stockout by value of cumsum just after it exceeds the stock amount
  cumulatedPredSales <- cumsum(predicted_sales)
  stockout_day <- min(which(cumulatedPredSales >= stock))

  if (is.na(stockout_day)) {
    stockout_day <- NA
  }
  return(list(best_model = best_model,forecast_days = stockout_day))
}


load_dot_env()
#drv <- DBI::dbDriver("PostgreSQL")
con <- dbConnect(RPostgres::Postgres(),dbname = Sys.getenv("DB_NAME"),
                 host = Sys.getenv("DB_HOST"),
                 port = (Sys.getenv("DB_PORT")),
                 user = Sys.getenv("DB_USER"),password = Sys.getenv("DB_PASS"))


data_items <- dbGetQuery(con, "SELECT id, name, amount FROM items
  ORDER BY id;")

data_sales <- dbGetQuery(con, "SELECT item_id, sales_date, amount_sold FROM sales
  ORDER BY item_id, sales_date;")


forecast_results <- data_sales %>% group_by(item_id) %>%
  summarise(sales_series = list(amount_sold),.groups = "drop") %>%
  left_join(data_items, by = c("item_id" = "id"))
library(dplyr)
library(forecast)
library(DBI)
library(RPostgres)
library(dotenv)

forecastFunc <- function(y, stock) {
  horizon <- 65
  train <- y[1:300]
  test  <- y[301:365]

  train_series <- ts(train, frequency = 7)
  test_vectorValues  <- as.numeric(test)

  model_arima  <- auto.arima(train_series)
  model_ets    <- ets(train_series)
  model_snaive <- snaive(train_series, h = 65)

  forecast_arima <- forecast(model_arima, h = 65)
  forecast_ets   <- forecast(model_ets, h = 65)
  forecast_snaive <- snaive(train_series, h = 65)

  rmse_arima   <- accuracy(forecast_arima, test_vectorValues)[2, "RMSE"]
  rmse_ets     <- accuracy(forecast_ets, test_vectorValues)[2, "RMSE"]
  rmse_snaive  <- accuracy(forecast_snaive, test_vectorValues)[2, "RMSE"]

  model_scores <- data.frame(
    model = c("ARIMA", "ETS", "SNAIVE"),
    RMSE  = c(rmse_arima, rmse_ets, rmse_snaive)
  )
  best_model <- model_scores$model[which.min(model_scores$RMSE)]

  full_s <- ts(y, frequency = 7)

  # refit best model on full data
  if (best_model == "ARIMA") {
    modFinal <- auto.arima(full_s)
    final_forecast <- forecast(modFinal, h = horizon)
  } else if (best_model == "ETS") {
    modFinal <- ets(full_s)
    final_forecast <- forecast(modFinal, h = horizon)
  } else {
    final_forecast <- snaive(full_s, h = horizon)
  }

  predicted_sales <- pmax(round(as.numeric(final_forecast$mean)), 0)
  # stockout by value of cumsum just after it exceeds the stock amount
  cumulatedPredSales <- cumsum(predicted_sales)
  stockout_day <- min(which(cumulatedPredSales >= stock))

  if (is.na(stockout_day)) {
    stockout_day <- NA
  }
  return(list(best_model = best_model,forecast_days = stockout_day))
}


load_dot_env()
#drv <- DBI::dbDriver("PostgreSQL")
con <- dbConnect(RPostgres::Postgres(),dbname = Sys.getenv("DB_NAME"),
                 host = Sys.getenv("DB_HOST"),
                 port = (Sys.getenv("DB_PORT")),
                 user = Sys.getenv("DB_USER"),password = Sys.getenv("DB_PASS"))


data_items <- dbGetQuery(con, "SELECT id, name, amount FROM items
  ORDER BY id;")

data_sales <- dbGetQuery(con, "SELECT item_id, sales_date, amount_sold FROM sales
  ORDER BY item_id, sales_date;")


forecast_results <- data_sales %>% group_by(item_id) %>%
  summarise(sales_series = list(amount_sold),.groups = "drop") %>%
  left_join(data_items, by = c("item_id" = "id"))

forecast_results <- forecast_results %>%rowwise() %>%
  mutate(result = list(forecastFunc(sales_series, amount)),
    model_name = result$best_model,forecast_days = result$forecast_days) %>%
  select(item_id, model_name, forecast_days) %>%ungroup()

forecast_results
forecast_results %>% count(model_name) # 6 arima #9 ETS


for (i in seq_len(nrow(forecast_results))) {
  dbExecute(con, "UPDATE items SET model_name = $1,items_date = CURRENT_DATE,
        forecast_days = $2 WHERE id = $3;",
  params = list(forecast_results$model_name[i],forecast_results$forecast_days[i],
             forecast_results$item_id[i]))
}

dbDisconnect(con)



forecast_results <- forecast_results %>%rowwise() %>%
  mutate(result = list(forecastFunc(sales_series, amount)),
         model_name = result$best_model,forecast_days = result$forecast_days) %>%
  select(item_id, model_name, forecast_days) %>%ungroup()

forecast_results
forecast_results %>% count(model_name) # 6 arima #9 ETS


for (i in seq_len(nrow(forecast_results))) {
  dbExecute(con, "UPDATE items SET model_name = $1,items_date = CURRENT_DATE,
        forecast_days = $2 WHERE id = $3;",
            params = list(forecast_results$model_name[i],forecast_results$forecast_days[i],
                          forecast_results$item_id[i]))
}

dbDisconnect(con)


