Project Title: Time Series Forecasting for Stockout Prediction in a Tile Inventory System Using Synthetic Sales Data


RCode/

Contains the R scripts used for:
synthetic data generation using an INGARCH process - Datagen.R
forecasting and stockout prediction - TileForcasting.R
statistical analysis and visualisation - DataViz.R

database/
Contains the SQL file used to create the PostgreSQL database schema. 

backend/
Contains the server.js that is used to retrieve item and sales data from PostgreSQL through API routes. 

frontend/
Contains the React frontend used to display tile items and sales charts.

What was used:
- R
- PostgreSQL
- Node.js
- Express
- React

Required R Packages
- tscount
- dplyr
- forecast
- ggplot2
- tseries
- DBI
- RPostgres
- dotenv
- viridis

Required Packages for app: 
- express
- pg
- cors
- react
- recharts

Database
The project uses a PostgreSQL database.

The database contains two tables:
- items
- sales

Backend API
The backend server is written in Node.js using Express.

API routes:
- /api/items  
- /api/items/:id/sales

Frontend
The frontend is a React application.
It fetches inventory data from the backend API and displays:
- tile item details
- estimated stockout days
- sales chart for the selected tile item

Steps to recreate the project: 
1. Create the PostgreSQL database
- Run the SQL schema file in the database folder to create the items and sales tables

2. Run the R scripts
- Run the data generation script first to give data to the database
- Run the forecasting script to calculate the best model and stockout days
- Run the visualisation script if needed for plots and diagnostics

3. Start the backend server then the frontend
- You need to install node modules yourself

