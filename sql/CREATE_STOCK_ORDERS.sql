CREATE TABLE STOCK_ORDERS
(ID INTEGER PRIMARY KEY AUTOINCREMENT,
 GAME VARCHAR(50),
 USER VARCHAR(50),
 COMMAND VARCHAR(50),
 NATION VARCHAR(50),
 QUANTITY INTEGER,
 TURN VARCHAT(10),
 EXEC_ORDER INTEGER);