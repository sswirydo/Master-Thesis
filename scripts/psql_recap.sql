
CREATE TABLE product_groups (
  group_id serial PRIMARY KEY,
  group_name VARCHAR(255) NOT NULL
);

CREATE TABLE products (
  product_id serial PRIMARY KEY,
  product_name VARCHAR(255) NOT NULL,
  price DECIMAL(11,2),
  group_id INT NOT NULL,
  FOREIGN KEY (group_id) REFERENCES product_groups(group_id)
);

INSERT INTO product_groups(group_name)
VALUES
  ('Smartphone'),
  ('Laptop'),
  ('Tablet');


INSERT INTO products (product_name, group_id, price)
VALUES
	('Microsoft Lumia', 1, 200),
	('HTC One', 1, 400),
	('Nexus', 1, 500),
	('iPhone', 1, 900),
	('HP Elite', 2, 1200),
	('Lenovo Thinkpad', 2, 700),
	('Sony VAIO', 2, 700),
	('Dell Vostro', 2, 800),
	('iPad', 3, 700),
	('Kindle Fire', 3, 150),
	('Samsung Galaxy Tab', 3, 200);

SELECT * FROM products;
SELECT AVG(price) FROM products;
SELECT group_id, AVG(price) as avg_price FROM products GROUP BY group_id ORDER BY avg_price ASC;

SELECT group_name, AVG(price) as avg_price 
	FROM products 
	INNER JOIN product_groups USING (group_id) 
	GROUP BY group_name 
	ORDER BY avg_price ASC;

SELECT group_name, product_name, price, AVG(price) OVER (PARTITION BY group_name)
	FROM products
	INNER JOIN product_groups USING (group_id)
	ORDER BY group_name, price;

SELECT group_name, product_name, price, AVG(price) OVER ()
	FROM products
	INNER JOIN product_groups USING (group_id)
	ORDER BY group_name, price;
