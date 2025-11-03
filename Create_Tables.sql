
-- Drop existing tables if they exist (for clean reload)
DROP TABLE IF EXISTS Auctions;
DROP TABLE IF EXISTS ReservationPassenger;
DROP TABLE IF EXISTS Includes;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS CustomerPreferences;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Person;
DROP TABLE IF EXISTS Fare;
DROP TABLE IF EXISTS Leg;
DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS AdvPurchaseDiscount;
DROP TABLE IF EXISTS Airport;
DROP TABLE IF EXISTS Airline;

-- CORE TABLES
-- Airline Table
CREATE TABLE Airline (
    Id CHAR(2) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL
);

-- Airport Table
CREATE TABLE Airport (
    Id CHAR(3) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL
);

-- Advance Purchase Discount Table
CREATE TABLE AdvPurchaseDiscount (
    AirlineID CHAR(2),
    Days INTEGER NOT NULL,
    DiscountRate NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (AirlineID, Days),
    FOREIGN KEY (AirlineID) REFERENCES Airline(Id),
    CHECK (Days > 0),
    CHECK (DiscountRate >= 0 AND DiscountRate <= 100)
);

-- Flight Table
CREATE TABLE Flight (
    AirlineID CHAR(2),
    FlightNo INTEGER NOT NULL,
    NoOfSeats INTEGER NOT NULL,
    DaysOperating CHAR(7) NOT NULL,
    MinLengthOfStay INTEGER NOT NULL,
    MaxLengthOfStay INTEGER NOT NULL,
    PRIMARY KEY (AirlineID, FlightNo),
    FOREIGN KEY (AirlineID) REFERENCES Airline(Id),
    CHECK (NoOfSeats > 0),
    CHECK (MinLengthOfStay >= 0),
    CHECK (MaxLengthOfStay >= MinLengthOfStay)
);

-- Leg Table (Flight segments)
CREATE TABLE Leg (
    AirlineID CHAR(2),
    FlightNo INTEGER NOT NULL,
    LegNo INTEGER NOT NULL,
    DepAirportID CHAR(3) NOT NULL,
    ArrAirportID CHAR(3) NOT NULL,
    DepTime DATETIME NOT NULL,
    ArrTime DATETIME NOT NULL,
    PRIMARY KEY (AirlineID, FlightNo, LegNo),
    UNIQUE (AirlineID, FlightNo, DepAirportID),
    FOREIGN KEY (AirlineID, FlightNo) REFERENCES Flight(AirlineID, FlightNo),
    FOREIGN KEY (DepAirportID) REFERENCES Airport(Id),
    FOREIGN KEY (ArrAirportID) REFERENCES Airport(Id),
    CHECK (LegNo > 0)
);

-- Fare Table
CREATE TABLE Fare (
    AirlineID CHAR(2),
    FlightNo INTEGER NOT NULL,
    FareType VARCHAR(20) NOT NULL,
    Class VARCHAR(20) NOT NULL,
    FareAmount NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (AirlineID, FlightNo, FareType, Class),
    FOREIGN KEY (AirlineID, FlightNo) REFERENCES Flight(AirlineID, FlightNo),
    CHECK (FareAmount > 0)
);

-- PERSON-RELATED TABLES
-- Person Table 
CREATE TABLE Person (
    Id INTEGER PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Address VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    State VARCHAR(50) NOT NULL,
    ZipCode INTEGER NOT NULL,
    Phone VARCHAR(15),
    CHECK (Id > 0),
    CHECK (ZipCode > 0)
);

-- Customer Table
CREATE TABLE Customer (
    Id INTEGER NOT NULL,
    AccountNo INTEGER PRIMARY KEY,
    CreditCardNo CHAR(16),
    Email VARCHAR(50),
    CreationDate DATETIME NOT NULL,
    Rating INTEGER,
    FOREIGN KEY (Id) REFERENCES Person(Id),
    CHECK (Rating >= 0 AND Rating <= 10)
);

-- Customer Preferences Table
CREATE TABLE CustomerPreferences (
    AccountNo INTEGER NOT NULL,
    Preference VARCHAR(50) NOT NULL,
    PRIMARY KEY (AccountNo, Preference),
    FOREIGN KEY (AccountNo) REFERENCES Customer(AccountNo)
);

-- Employee Table
CREATE TABLE Employee (
    Id INTEGER NOT NULL,
    SSN INTEGER PRIMARY KEY,
    IsManager BOOLEAN NOT NULL,
    StartDate DATE NOT NULL,
    HourlyRate NUMERIC(10,2) NOT NULL,
    FOREIGN KEY (Id) REFERENCES Person(Id),
    UNIQUE (Id),
    CHECK (SSN > 0),
    CHECK (HourlyRate > 0)
);

-- Passenger Table (links persons who are passengers to customer accounts)
CREATE TABLE Passenger (
    Id INTEGER,
    AccountNo INTEGER,
    PRIMARY KEY (Id, AccountNo),
    FOREIGN KEY (Id) REFERENCES Person(Id),
    FOREIGN KEY (AccountNo) REFERENCES Customer(AccountNo)
);

-- RESERVATION TABLES
-- Reservation Table
CREATE TABLE Reservation (
    ResrNo INTEGER PRIMARY KEY,
    ResrDate DATETIME NOT NULL,
    BookingFee NUMERIC(10,2) NOT NULL,
    TotalFare NUMERIC(10,2) NOT NULL,
    RepSSN INTEGER,
    AccountNo INTEGER NOT NULL,
    FOREIGN KEY (RepSSN) REFERENCES Employee(SSN),
    FOREIGN KEY (AccountNo) REFERENCES Customer(AccountNo),
    CHECK (ResrNo > 0),
    CHECK (BookingFee > 0),
    CHECK (TotalFare >= BookingFee)
);

-- Includes Table (link reservations to flight legs)
CREATE TABLE Includes (
    ResrNo INTEGER,
    AirlineID CHAR(2),
    FlightNo INTEGER,
    LegNo INTEGER,
    Date DATE NOT NULL,
    PRIMARY KEY (ResrNo, AirlineID, FlightNo, LegNo),
    FOREIGN KEY (ResrNo) REFERENCES Reservation(ResrNo),
    FOREIGN KEY (AirlineID, FlightNo, LegNo) REFERENCES Leg(AirlineID, FlightNo, LegNo)
);

-- ReservationPassenger Table (link passengers to reservations with seat info)
CREATE TABLE ReservationPassenger (
    ResrNo INTEGER,
    Id INTEGER,
    AccountNo INTEGER,
    SeatNo CHAR(5) NOT NULL,
    Class VARCHAR(20) NOT NULL,
    Meal VARCHAR(50),
    PRIMARY KEY (ResrNo, Id, AccountNo),
    FOREIGN KEY (ResrNo) REFERENCES Reservation(ResrNo),
    FOREIGN KEY (Id, AccountNo) REFERENCES Passenger(Id, AccountNo)
);

-- Auctions Table 
CREATE TABLE Auctions (
    AccountNo INTEGER,
    AirlineID CHAR(2),
    FlightNo INTEGER,
    LegNo INTEGER,
    Class VARCHAR(20),
    Date DATETIME,
    NYOP NUMERIC(10,2) NOT NULL,
    Accepted BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (AccountNo, AirlineID, FlightNo, LegNo, Date),
    FOREIGN KEY (AccountNo) REFERENCES Customer(AccountNo),
    FOREIGN KEY (AirlineID, FlightNo, LegNo) REFERENCES Leg(AirlineID, FlightNo, LegNo),
    CHECK (NYOP > 0)
);

