CREATE TABLE BOP_MISSIONS
(ID INTEGER PRIMARY KEY AUTOINCREMENT,
 TYPE VARCHAR(50),
 ASSIGNED INTEGER,
 EXPIRE_TURN VARCHAR(10),
 STATUS INTEGER,
 PROGRESS INTEGER,
 CONFIGURATION TEXT,
 REWARD TEXT,
 LOCATION VARCHAR(50)
);
