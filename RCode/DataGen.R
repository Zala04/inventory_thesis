library(tscount)
library(dplyr)
library(DBI)
library(RPostgres)
library(dotenv)

set.seed(22473462)

n_items <- 15
n_days <- 365
#  dates
dates <- seq.Date(as.Date("2025-01-01"), by = "day", length.out = n_days)

# generic names not important
item_names <- paste0("Tile ", LETTERS[1:n_items])

# necessary matrix for weekend effect
Weekend <- c()
for (i in 1:length(dates)) {
  day <- weekdays(dates[i])
  if (day == "Saturday" || day == "Sunday") {
    Weekend[i] <- 1
  } else {
    Weekend[i] <- 0
  }
}


xreg <- as.matrix(Weekend)
#print(xreg)
colnames(xreg) <- "Weekend"

item_ids <- 1:n_items
random_prices <- round(runif(n_items, 11, 40))
item_amounts <- sample(100:200, n_items, replace = TRUE)
randomIntercepts <- runif(n_items,1.1, 1.8)
item_past_obs <- runif(n_items,0.20, 0.4)
item_past_mean <- runif(n_items, 0.2, 0.3)
weekend_effect <- c(Weekend = -0.1)

sim_list <- list()
for (i in 1:n_items) {
  sim <- tsglm.sim(
    n = n_days,
    model = list(past_obs = 1,past_mean = 1),
    param = list(intercept = randomIntercepts[i],
                 past_obs = item_past_obs[i],
                 past_mean = item_past_mean[i],
                 xreg = weekend_effect),
    xreg = xreg,
    link = "log",
    distr = "poisson")

  byItem <- data.frame(item_id = item_ids[i],
                       sales_date = dates,amount_sold = as.integer(sim$ts))

  sim_list[[i]] <- byItem
}


total_sales <- bind_rows(sim_list) # into one df

#print(head(total_items))
#print(head(total_sales))

# items table
total_items <- data.frame(
  id = item_ids,
  name = item_names,
  price = random_prices,
  amount = item_amounts,
  model_name = NA,
  forecast_days = NA
)

load_dot_env()
con <- dbConnect(RPostgres::Postgres(),dbname = Sys.getenv("DB_NAME"),
                 host = Sys.getenv("DB_HOST"),port = as.integer(Sys.getenv("DB_PORT")),
                 user = Sys.getenv("DB_USER"),password = Sys.getenv("DB_PASS"))

# to delete old data for testing new intercepts
dbExecute(con, "DELETE FROM sales;")
dbExecute(con, "DELETE FROM items;")

# write new data
dbWriteTable(con, "items", total_items, append = TRUE, row.names = FALSE)
dbWriteTable(con, "sales", total_sales, append = TRUE, row.names = FALSE)

dbDisconnect(con)

