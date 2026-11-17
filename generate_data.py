"""Generates a SAMPLE (synthetic) sales dataset for a small Indian apparel brand.
All figures are random and made up for portfolio/demo purposes."""
import csv, random
from datetime import date, timedelta

random.seed(42)
products = [  # id, name, category, price (INR)
    (1, "Ajrakh Kurta", "Kurta", 2499), (2, "Bandhani Dupatta", "Dupatta", 1299),
    (3, "Modal Silk Saree", "Saree", 5999), (4, "Indo-Western Jacket", "Jacket", 3499),
    (5, "Block Print Shirt", "Shirt", 1799), (6, "Cotton Palazzo", "Bottoms", 999),
    (7, "Festive Lehenga Set", "Lehenga", 8999), (8, "Ajrakh Stole", "Dupatta", 899),
]
channels = ["Instagram", "Website", "Exhibition", "WhatsApp"]
cities = ["Ahmedabad", "Mumbai", "Bengaluru", "Delhi", "Pune", "Surat", "Jaipur"]

with open("products.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["product_id", "product_name", "category", "price"]); w.writerows(products)

customers = [(i, random.choice(cities)) for i in range(1, 1501)]
with open("customers.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["customer_id", "city"]); w.writerows(customers)

rows, oid, start = [], 1, date(2025, 11, 1)
for d in range(365):
    day = start + timedelta(days=d)
    festive = day.month in (10, 11) or (day.month == 3 and day.day < 20)
    for _ in range(random.randint(3, 9) + (6 if festive else 0)):
        p = random.choice(products)
        qty = random.choices([1, 2, 3], [80, 15, 5])[0]
        disc = random.choice([0, 0, 0, 5, 10, 15]) + (5 if festive else 0)
        rows.append([oid, day.isoformat(), random.randint(1, 1500), p[0], qty,
                     random.choices(channels, [45, 25, 15, 15])[0], disc,
                     random.random() < 0.06])
        oid += 1
with open("orders.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["order_id", "order_date", "customer_id", "product_id", "quantity", "channel", "discount_pct", "returned"])
    w.writerows([r[:-1] + [int(r[-1])] for r in rows])
print(f"Generated {len(rows)} orders, {len(customers)} customers, {len(products)} products")
