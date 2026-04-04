import React, { useEffect, useState } from "react";
import {LineChart,Line,XAxis,YAxis,Tooltip,CartesianGrid,ResponsiveContainer
} from "recharts";

const apiUrl = import.meta.env.VITE_BASE_URL

function App() {

  const [items, setItems] = useState([]);
  const [sales, setSales] = useState([]);
  const [selectedId, setSelectedId] = useState(null);


  // fetch items and select first as def
  useEffect(function () {
    fetch(`${apiUrl}/api/items`)
      .then(res => res.json())
      .then(data => {
        setItems(data);
        if (data.length > 0) {
          setSelectedId(data[0].id);
        }
      });
  }, []);

  // fetch sales for sel itme

  useEffect(function () {
    if (selectedId !== null) {
      fetch(`${apiUrl}/api/items/${selectedId}/sales`)
        .then(res => res.json())
        .then(data => setSales(data));
    }
  }, [selectedId]);

  const selectedItem = items.find(function (item) {
    return item.id === selectedId;
  });

// formate dater improvised from stackoverflow and changed it to match my use case 
 function formatDate(date) {
  let parts = date.split("T")[0].split("-");
  return parts[1] + "/" + parts[0];
}

// chart 
  return (
    <div className="container">
      <h1>Tile Inventory</h1>

      <div className="tables">
        <div className="section">
          <h2>Tile Items</h2>

          <table id="itemsTable">
            <thead>
              <tr>
                <th>Name</th>
                <th>Amount</th>
                <th>Price</th>
                <th>Estimated Stockout in:</th>
              </tr>
            </thead>

            <tbody>
              {items.map(function (item) {
                return (
                  <tr
                    key={item.id}
                    onClick={function () {
                      setSelectedId(item.id);
                    }}
                    className={item.id === selectedId ? "selected" : ""}
                  >
                    <td>{item.name}</td>
                    <td>{item.amount}</td>
                    <td>€{item.price}</td>
                    <td>{item.forecast_days} days </td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          <table id="moveTable">
            <thead>
              <tr>
                <th>Item</th>
                <th>Quantity</th>
              </tr>
            </thead>

            <tbody>
              <tr>
                <td>{selectedItem ? selectedItem.name : "Select Item"}</td>
                <td>
                  <input type="number" placeholder="Enter qty" />
                </td>
                <td>
                  <button>Add Stock</button>
                  <button style={{ marginLeft: "8px" }}>Sell Stock</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="section">
          <h2>Sales Chart</h2>

          <div className="chartBox">
            <ResponsiveContainer width="500" height="500">
              <LineChart data={sales}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="sales_date" tickFormatter={formatDate} />
                <YAxis />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="amount_sold"
                  stroke="#8884d8"
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;