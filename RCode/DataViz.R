library(dplyr)
library(forecast)
library(ggplot2)
library(tseries)
library(DBI)
library(dotenv)
library(viridis)


load_dot_env()
con <- dbConnect(RPostgres::Postgres(),dbname = Sys.getenv("DB_NAME"),
                 host = Sys.getenv("DB_HOST"),port = as.integer(Sys.getenv("DB_PORT")),
                 user = Sys.getenv("DB_USER"),password = Sys.getenv("DB_PASS"))
dbIsValid(con)

items_db <- dbGetQuery(con, "
  SELECT id, name, price, amount, items_date, model_name, forecast_days
  FROM items
  ORDER BY id;
")

sales_db <- dbGetQuery(con, "
  SELECT item_id, sales_date, amount_sold
  FROM sales
  ORDER BY item_id, sales_date;
")

dbDisconnect(con)


item1 <- items_db %>%
  filter(name == "Tile A")

tile1 <- sales_db %>%
  filter(item_id == item1$id) %>%
  arrange(sales_date)

y <- tile1$amount_sold

autoplot(ts(y)) +
  autolayer(ts(y)) +
  ggtitle("first tile TS") +
  xlab("Time") +
  ylab("Sales")

train <- y[1:300]
test <- y[301:365]

train_ts <- ts(train, frequency = 7)
test_ts  <- ts(test, start = end(train_ts) + c(0, 1), frequency = 7)
# c(0,1) is needed to move the plot up as its been 300 training so to finish the
# cycle it needs to be 301


autoplot(train_ts) +
  ggtitle("Tile A Training Series") +
  xlab("Time") +
  ylab("Sales")

ggplot(tile1, aes(x = amount_sold)) +
  geom_density(colour="red") +
  ggtitle("Tile A Density") +
  xlab("Daily Sales")


fit_arima <- auto.arima(train_ts)
fit_ets <- ets(train_ts)
fit_snaive <- snaive(train_ts, h = length(test))

fc_arima <- forecast(fit_arima, h = length(test))
fc_ets <- forecast(fit_ets, h = length(test))
fc_snv <- fit_snaive

summary(fit_arima)
summary(fit_ets)


rmse_arima <- as.numeric(accuracy(fc_arima, as.numeric(test_ts))["Test set", "RMSE"])

rmse_ets <- as.numeric(accuracy(fc_ets, as.numeric(test_ts))["Test set", "RMSE"])

rmse_snv <- as.numeric(accuracy(fc_snv, as.numeric(test_ts))["Test set", "RMSE"])

mae_arima <- as.numeric(accuracy(fc_arima, as.numeric(test_ts))["Test set", "MAE"])

mae_ets <- as.numeric(accuracy(fc_ets, as.numeric(test_ts))["Test set", "MAE"])

mae_snv <- as.numeric(accuracy(fc_snv, as.numeric(test_ts))["Test set", "MAE"])

scores <- data.frame(
  model = c("ARIMA", "ETS", "SNAIVE"),
  RMSE = c(rmse_arima, rmse_ets, rmse_snv),
  MAE = c(mae_arima, mae_ets, mae_snv)
)


best_model_tile1 <- scores$model[which.min(scores$RMSE)]
best_model_tile1


checkresiduals(fit_arima)

checkresiduals(fit_ets)



# stl decomp of the first tile
stl_decomp_s <- ts((as.vector(y)), frequency = 7)
stl(stl_decomp_s, s.window = "periodic", robust = FALSE) %>% autoplot()


auto.arima(ts(y))

checkresiduals(fit_arima)

adf.test(train_ts)
kpss.test(train_ts)
adf.test(y)

autoplot(train_ts, series = "Train") +
  autolayer(fc_arima$mean, series = "ARIMA") +
  autolayer(fc_ets$mean, series = "ETS") +
  autolayer(fc_snv$mean, series = "SNAIVE") +
  autolayer(test_ts, series = "Test") +
  ggtitle("Tile A") +
  xlab("Time") +
  ylab("Sales")

autoplot(fc_arima) +
  autolayer(test_ts, series = "Test") +
  ggtitle("ARIMA with prediction intervals ") +
  xlab("Time") +
  ylab("Sales")

ggplot(items_db, aes(x = amount, y = forecast_days)) +
  geom_point() +
  ggtitle("Stock amount vs stockout days") +
  xlab("Stock Amount") +
  ylab("Days until stockout ")

heatmapData <- sales_db %>%
  left_join(items_db, by = c("item_id" = "id"))


ggplot(tile1, aes(x = amount_sold)) +
  geom_density() +
  geom_vline(aes(xintercept = mean(amount_sold)),
             linetype = 1, colour = "red") +
  xlab("Daily Sales") +
  ylab("Density") +
  ggtitle("Tile A Density")


mean(tile1$amount_sold)

ggplot(heatmapData, aes(x = sales_date, y = name, fill = amount_sold)) +
  geom_tile() +
  ggtitle("Daily Sales for each Item") +
  scale_fill_viridis_c() +
  xlab("Date") +
  ylab("Item") +
  scale_x_date(
    limits = c(as.Date("2025-01-01"), as.Date("2026-01-01")))


