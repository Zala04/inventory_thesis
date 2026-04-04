import express from "express";
import pg from "pg";
import cors from "cors";

const app = express();
const { Pool } = pg;

app.use(cors());
app.use(express.json());

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASS,
  port: process.env.DB_PORT,
});

// items from database
app.get("/api/items", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, amount, price, forecast_days, model_name FROM items ORDER BY id"
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "failed to get" });
  }
});

   // sales for item selected
app.get("/api/items/:id/sales", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "id is invalid " });
  }
  try {
    const result = await pool.query(
      "SELECT sales_date, amount_sold FROM sales WHERE item_id = $1 ORDER BY sales_date ASC",
      [id]
    );
    res.json(result.rows);
  } catch (err) {
    console.log(err);
    res.status(500).json({ error: "failed to get s" });
  }
});

app.listen(3001, () => {
  console.log("Server running on port 3001");
});