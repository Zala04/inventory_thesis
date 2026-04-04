FROM rocker/tidyverse

# System dependencies for RPostgres + forecast/tscount
RUN apt-get update && apt-get install -y libpq-dev && apt-get clean

# Install the remaining R packages
RUN R -e "install.packages(c('tscount', 'forecast', 'RPostgres', 'dotenv'), repos='https://cloud.r-project.org')"

WORKDIR /app

# COPY DataGen.R TileForecasting.R run_all.sh /app

CMD ["/app/run_all.sh"]
