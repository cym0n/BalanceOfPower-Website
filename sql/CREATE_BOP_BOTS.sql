CREATE TABLE BOP_BOTS
(ID INTEGER PRIMARY KEY AUTOINCREMENT,
 GAME VARCHAR(100),
 NAME VARCHAR(100),
 CLASS VARCHAR(100),
 PHOTO VARCHAR(100),
 NATION VARCHAR(50),
 POSITION VARCHAR(50),
 DESTINATION VARCHAR(50),
 ARRIVAL_TIME TIMESTAMP,
 DISEMBARK_TIME TIMESTAMP
);
