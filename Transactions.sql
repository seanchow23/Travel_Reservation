-- ============================================================================
-- CSE 305 - PROJECT 2: SQL DML STATEMENTS
-- SECTION 3.1: MANAGER-LEVEL TRANSACTIONS (13 Transactions)
-- Online Travel Reservation System
-- ============================================================================
-- 
-- Team Name: [INSERT YOUR TEAM NAME HERE]
-- 
-- Team Members:
--   1. [Name] - [Email]
--   2. [Name] - [Email]
--   3. [Name] - [Email]
-- 
-- Submission Date: November 3, 2025
-- 
-- ============================================================================
-- This file contains all 13 Manager-Level transactions from Section 3.1
-- Each transaction is ready to test against your demo database
-- ============================================================================

USE project_2;

-- ============================================================================
-- TRANSACTION 3.1.1: Add Employee
-- ============================================================================

-- Definition: 
-- Add a new employee to the system (customer representative or manager)

-- Input Parameters:
--   @PersonId      INTEGER       - Unique person identifier
--   @FirstName     VARCHAR(50)   - Employee first name
--   @LastName      VARCHAR(50)   - Employee last name
--   @Address       VARCHAR(100)  - Street address
--   @City          VARCHAR(50)   - City
--   @State         VARCHAR(50)   - State
--   @ZipCode       INTEGER       - ZIP code
--   @Phone         VARCHAR(15)   - Phone number
--   @SSN           INTEGER       - Social Security Number (unique)
--   @IsManager     BOOLEAN       - TRUE if manager, FALSE if customer rep
--   @StartDate     DATE          - Employment start date
--   @HourlyRate    DECIMAL(10,2) - Hourly wage rate

-- SQL Statement (Parameterized):
/*
INSERT INTO Person (Id, FirstName, LastName, Address, City, State, ZipCode, Phone)
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

INSERT INTO Employee (Id, SSN, IsManager, StartDate, HourlyRate)
VALUES (?, ?, ?, ?, ?);
*/

-- Execution Example (Test with these values):

INSERT INTO Person (Id, FirstName, LastName, Address, City, State, ZipCode, Phone)
VALUES (104, 'David', 'Brown', '200 Oak Street', 'Stony Brook', 'NY', 11790, '631-555-0004');

INSERT INTO Employee (Id, SSN, IsManager, StartDate, HourlyRate)
VALUES (104, 111222333, FALSE, '2025-11-01', 28.00);

-- Verification Query (Run this to see the result):
SELECT E.SSN, P.FirstName, P.LastName, P.Phone, E.IsManager, 
       E.StartDate, E.HourlyRate
FROM Employee E
JOIN Person P ON E.Id = P.Id
WHERE E.SSN = 111222333;

-- Expected Output:
-- +-----------+-----------+----------+---------------+-----------+------------+------------+
-- | SSN       | FirstName | LastName | Phone         | IsManager | StartDate  | HourlyRate |
-- +-----------+-----------+----------+---------------+-----------+------------+------------+
-- | 111222333 | David     | Brown    | 631-555-0004  |         0 | 2025-11-01 |      28.00 |
-- +-----------+-----------+----------+---------------+-----------+------------+------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes: 
-- Both Person and Employee records must be inserted. Person.Id and Employee.Id 
-- must match. SSN must be unique.

-- ============================================================================
-- TRANSACTION 3.1.2: Edit Employee
-- ============================================================================

-- Definition:
-- Modify existing employee information (hourly rate, manager status, contact info)

-- Input Parameters:
--   @SSN           INTEGER       - Employee SSN (identifies the employee)
--   @NewHourlyRate DECIMAL(10,2) - Updated hourly rate (optional)
--   @NewIsManager  BOOLEAN       - Updated manager status (optional)
--   @NewPhone      VARCHAR(15)   - Updated phone (optional)
--   [Other fields as needed]

-- SQL Statement (Parameterized):
/*
UPDATE Employee
SET HourlyRate = ?,
    IsManager = ?
WHERE SSN = ?;

UPDATE Person
SET Phone = ?
WHERE Id = (SELECT Id FROM Employee WHERE SSN = ?);
*/

-- Execution Example (Give Alice Johnson a raise and promote to manager):

UPDATE Employee
SET HourlyRate = 30.00,
    IsManager = TRUE
WHERE SSN = 123456789;

UPDATE Person
SET Phone = '631-555-9999'
WHERE Id = (SELECT Id FROM Employee WHERE SSN = 123456789);

-- Verification Query:
SELECT E.SSN, P.FirstName, P.LastName, P.Phone, E.IsManager, E.HourlyRate
FROM Employee E
JOIN Person P ON E.Id = P.Id
WHERE E.SSN = 123456789;

-- Expected Output:
-- +-----------+-----------+----------+---------------+-----------+------------+
-- | SSN       | FirstName | LastName | Phone         | IsManager | HourlyRate |
-- +-----------+-----------+----------+---------------+-----------+------------+
-- | 123456789 | Alice     | Johnson  | 631-555-9999  |         1 |      30.00 |
-- +-----------+-----------+----------+---------------+-----------+------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Can update employee-specific fields (HourlyRate, IsManager) and person fields
-- (Phone, Address, etc.). Only provided fields should be updated.

-- ============================================================================
-- TRANSACTION 3.1.3: Delete Employee
-- ============================================================================

-- Definition:
-- Remove an employee from the system

-- Input Parameters:
--   @SSN INTEGER - Employee SSN to delete

-- SQL Statement (Parameterized):
/*
DELETE FROM Employee WHERE SSN = ?;
DELETE FROM Person WHERE Id = (SELECT Id FROM Employee WHERE SSN = ?);
*/

-- Execution Example (First add a test employee, then delete):

-- Add test employee
INSERT INTO Person VALUES (105, 'Test', 'Employee', '123 Test St', 'Test City', 'NY', 11111, '555-0000');
INSERT INTO Employee VALUES (105, 999888777, FALSE, '2025-01-01', 20.00);

-- Now delete the test employee
DELETE FROM Employee WHERE SSN = 999888777;
DELETE FROM Person WHERE Id = 105;

-- Verification Query:
SELECT COUNT(*) AS EmployeeExists FROM Employee WHERE SSN = 999888777;

-- Expected Output:
-- +----------------+
-- | EmployeeExists |
-- +----------------+
-- |              0 |
-- +----------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- This will fail if employee has reservations (RepSSN foreign key constraint).
-- In production, either set RepSSN to NULL first or prevent deletion.

-- ============================================================================
-- TRANSACTION 3.1.4: Obtain Sales Report for a Particular Month
-- ============================================================================

-- Definition:
-- Generate a sales summary report for a specific month showing total reservations,
-- revenue, booking fees, and statistics

-- Input Parameters:
--   @Month INTEGER - Month number (1-12)
--   @Year  INTEGER - Year (e.g., 2011)

-- SQL Statement (Parameterized):
/*
SELECT 
    ? AS Month,
    ? AS Year,
    COUNT(*) AS TotalReservations,
    SUM(TotalFare) AS TotalRevenue,
    SUM(BookingFee) AS TotalBookingFees,
    SUM(TotalFare - BookingFee) AS NetToAirlines,
    AVG(TotalFare) AS AverageFare,
    MIN(TotalFare) AS MinimumFare,
    MAX(TotalFare) AS MaximumFare
FROM Reservation
WHERE MONTH(ResrDate) = ? AND YEAR(ResrDate) = ?;
*/

-- Execution Example (Sales report for January 2011):

SELECT 
    1 AS Month,
    2011 AS Year,
    COUNT(*) AS TotalReservations,
    SUM(TotalFare) AS TotalRevenue,
    SUM(BookingFee) AS TotalBookingFees,
    SUM(TotalFare - BookingFee) AS NetToAirlines,
    AVG(TotalFare) AS AverageFare,
    MIN(TotalFare) AS MinimumFare,
    MAX(TotalFare) AS MaximumFare
FROM Reservation
WHERE MONTH(ResrDate) = 1 AND YEAR(ResrDate) = 2011;

-- Expected Output:
-- +-------+------+-------------------+--------------+-------------------+---------------+-------------+-------------+-------------+
-- | Month | Year | TotalReservations | TotalRevenue | TotalBookingFees  | NetToAirlines | AverageFare | MinimumFare | MaximumFare |
-- +-------+------+-------------------+--------------+-------------------+---------------+-------------+-------------+-------------+
-- |     1 | 2011 |                 3 |      5033.33 |            503.33 |       4530.00 |     1677.78 |      500.00 |     3333.33 |
-- +-------+------+-------------------+--------------+-------------------+---------------+-------------+-------------+-------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- All three demo reservations are in January 2011. Query returns one row even if
-- no reservations found (with NULL/0 values).

-- ============================================================================
-- TRANSACTION 3.1.5: Produce Comprehensive Listing of All Flights
-- ============================================================================

-- Definition:
-- List all flights in the system with airline information, route, and leg details

-- Input Parameters: None

-- SQL Statement:

SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    F.NoOfSeats,
    F.DaysOperating,
    F.MinLengthOfStay,
    F.MaxLengthOfStay,
    COUNT(L.LegNo) AS NumberOfLegs,
    GROUP_CONCAT(
        CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
        ORDER BY L.LegNo 
        SEPARATOR ', '
    ) AS Route
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
LEFT JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats, F.DaysOperating,
         F.MinLengthOfStay, F.MaxLengthOfStay
ORDER BY F.AirlineID, F.FlightNo;

-- Expected Output:
-- +-----------+-------------------+----------+-----------+---------------+-----------------+-----------------+--------------+----------------------+
-- | AirlineID | AirlineName       | FlightNo | NoOfSeats | DaysOperating | MinLengthOfStay | MaxLengthOfStay | NumberOfLegs | Route                |
-- +-----------+-------------------+----------+-----------+---------------+-----------------+-----------------+--------------+----------------------+
-- | AA        | American Airlines |      111 |       100 | 1010100       |               0 |              30 |            2 | LGA->LAX, LAX->HND   |
-- | AM        | Air Madagascar    |     1337 |        33 | 0000011       |               3 |              14 |            1 | JFK->TNR             |
-- | JB        | JetBlue Airways   |      111 |       150 | 1111111       |               0 |              30 |            2 | SFO->BOS, BOS->LHR   |
-- +-----------+-------------------+----------+-----------+---------------+-----------------+-----------------+--------------+----------------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- DaysOperating is a 7-bit string where 1=operates, 0=doesn't operate (Sun-Sat).
-- Shows complete flight information including route summary.

-- ============================================================================
-- TRANSACTION 3.1.6a: Produce List of Reservations by Flight Number
-- ============================================================================

-- Definition:
-- List all reservations for a specific flight including passenger details

-- Input Parameters:
--   @AirlineID CHAR(2)  - Airline code (e.g., 'AA')
--   @FlightNo  INTEGER  - Flight number

-- SQL Statement (Parameterized):
/*
SELECT 
    R.ResrNo,
    R.ResrDate,
    R.TotalFare,
    R.BookingFee,
    P.FirstName,
    P.LastName,
    C.Email,
    P.Phone,
    RP.SeatNo,
    RP.Class,
    RP.Meal
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Passenger PS ON RP.Id = PS.Id AND RP.AccountNo = PS.AccountNo
JOIN Person P ON PS.Id = P.Id
JOIN Customer C ON PS.AccountNo = C.AccountNo
WHERE I.AirlineID = ? AND I.FlightNo = ?
ORDER BY R.ResrNo, RP.SeatNo;
*/

-- Execution Example (Reservations for American Airlines Flight 111):

SELECT 
    R.ResrNo,
    R.ResrDate,
    R.TotalFare,
    R.BookingFee,
    P.FirstName,
    P.LastName,
    C.Email,
    P.Phone,
    RP.SeatNo,
    RP.Class,
    RP.Meal
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Passenger PS ON RP.Id = PS.Id AND RP.AccountNo = PS.AccountNo
JOIN Person P ON PS.Id = P.Id
JOIN Customer C ON PS.AccountNo = C.AccountNo
WHERE I.AirlineID = 'AA' AND I.FlightNo = 111
ORDER BY R.ResrNo, RP.SeatNo;

-- Expected Output:
-- +--------+---------------------+-----------+------------+-----------+----------+-------------------+--------------+--------+---------+-------+
-- | ResrNo | ResrDate            | TotalFare | BookingFee | FirstName | LastName | Email             | Phone        | SeatNo | Class   | Meal  |
-- +--------+---------------------+-----------+------------+-----------+----------+-------------------+--------------+--------+---------+-------+
-- |    111 | 2011-01-05 00:00:00 |   1200.00 |     120.00 | John      | Doe      | jdoe@woot.com     | 123-123-1234 | 33F    | Economy | Chips |
-- +--------+---------------------+-----------+------------+-----------+----------+-------------------+--------------+--------+---------+-------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Shows passenger details for each reservation on the flight. Multiple passengers
-- per reservation would show multiple rows.

-- ============================================================================
-- TRANSACTION 3.1.6b: Produce List of Reservations by Customer Name
-- ============================================================================

-- Definition:
-- List all reservations for a specific customer by searching their name

-- Input Parameters:
--   @LastName  VARCHAR(50) - Customer last name
--   @FirstName VARCHAR(50) - Customer first name (optional, NULL for any)

-- SQL Statement (Parameterized):
/*
SELECT 
    R.ResrNo,
    R.ResrDate,
    R.TotalFare,
    R.BookingFee,
    P.FirstName,
    P.LastName,
    C.AccountNo,
    C.Email,
    COUNT(DISTINCT I.LegNo) AS NumberOfLegs
FROM Reservation R
JOIN Customer C ON R.AccountNo = C.AccountNo
JOIN Person P ON C.Id = P.Id
LEFT JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE P.LastName = ?
  AND (? IS NULL OR P.FirstName = ?)
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee,
         P.FirstName, P.LastName, C.AccountNo, C.Email
ORDER BY R.ResrDate DESC;
*/

-- Execution Example (Find all reservations for customer "Doe"):

SELECT 
    R.ResrNo,
    R.ResrDate,
    R.TotalFare,
    R.BookingFee,
    P.FirstName,
    P.LastName,
    C.AccountNo,
    C.Email,
    COUNT(DISTINCT I.LegNo) AS NumberOfLegs
FROM Reservation R
JOIN Customer C ON R.AccountNo = C.AccountNo
JOIN Person P ON C.Id = P.Id
LEFT JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE P.LastName = 'Doe'
  AND (NULL IS NULL OR P.FirstName = NULL)
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee,
         P.FirstName, P.LastName, C.AccountNo, C.Email
ORDER BY R.ResrDate DESC;

-- Expected Output:
-- +--------+---------------------+-----------+------------+-----------+----------+-----------+-------------------+--------------+
-- | ResrNo | ResrDate            | TotalFare | BookingFee | FirstName | LastName | AccountNo | Email             | NumberOfLegs |
-- +--------+---------------------+-----------+------------+-----------+----------+-----------+-------------------+--------------+
-- |    111 | 2011-01-05 00:00:00 |   1200.00 |     120.00 | John      | Doe      |       222 | jdoe@woot.com     |            2 |
-- +--------+---------------------+-----------+------------+-----------+----------+-----------+-------------------+--------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- FirstName parameter can be NULL to search by last name only. Returns all
-- reservations for matching customers.

-- ============================================================================
-- TRANSACTION 3.1.7a: Revenue Generated by a Particular Flight
-- ============================================================================

-- Definition:
-- Calculate total revenue generated by a specific flight

-- Input Parameters:
--   @AirlineID CHAR(2)  - Airline code
--   @FlightNo  INTEGER  - Flight number

-- SQL Statement (Parameterized):
/*
SELECT 
    I.AirlineID,
    A.Name AS AirlineName,
    I.FlightNo,
    COUNT(DISTINCT R.ResrNo) AS TotalReservations,
    COUNT(DISTINCT RP.Id) AS TotalPassengers,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    SUM(R.TotalFare - R.BookingFee) AS NetToAirline,
    AVG(R.TotalFare) AS AverageFare
FROM Includes I
JOIN Reservation R ON I.ResrNo = R.ResrNo
JOIN Airline A ON I.AirlineID = A.Id
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
WHERE I.AirlineID = ? AND I.FlightNo = ?
GROUP BY I.AirlineID, A.Name, I.FlightNo;
*/

-- Execution Example (Revenue for American Airlines Flight 111):

SELECT 
    I.AirlineID,
    A.Name AS AirlineName,
    I.FlightNo,
    COUNT(DISTINCT R.ResrNo) AS TotalReservations,
    COUNT(DISTINCT RP.Id) AS TotalPassengers,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    SUM(R.TotalFare - R.BookingFee) AS NetToAirline,
    AVG(R.TotalFare) AS AverageFare
FROM Includes I
JOIN Reservation R ON I.ResrNo = R.ResrNo
JOIN Airline A ON I.AirlineID = A.Id
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
WHERE I.AirlineID = 'AA' AND I.FlightNo = 111
GROUP BY I.AirlineID, A.Name, I.FlightNo;

-- Expected Output:
-- +-----------+-------------------+----------+-------------------+-----------------+--------------+-------------------+--------------+-------------+
-- | AirlineID | AirlineName       | FlightNo | TotalReservations | TotalPassengers | TotalRevenue | TotalBookingFees  | NetToAirline | AverageFare |
-- +-----------+-------------------+----------+-------------------+-----------------+--------------+-------------------+--------------+-------------+
-- | AA        | American Airlines |      111 |                 1 |               1 |      1200.00 |            120.00 |      1080.00 |     1200.00 |
-- +-----------+-------------------+----------+-------------------+-----------------+--------------+-------------------+--------------+-------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Shows total revenue including breakdown of booking fees (company profit) and
-- net to airline. Useful for financial reporting.

-- ============================================================================
-- TRANSACTION 3.1.7b: Revenue Generated by a Destination City
-- ============================================================================

-- Definition:
-- Calculate total revenue for all flights arriving at a specific city

-- Input Parameters:
--   @DestinationCity VARCHAR(50) - Destination city name

-- SQL Statement (Parameterized):
/*
SELECT 
    AP.City AS DestinationCity,
    AP.Country,
    COUNT(DISTINCT R.ResrNo) AS TotalReservations,
    COUNT(DISTINCT RP.Id) AS TotalPassengers,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    AVG(R.TotalFare) AS AverageFare
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport AP ON L.ArrAirportID = AP.Id
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
WHERE AP.City = ?
GROUP BY AP.City, AP.Country;
*/

-- Execution Example (Revenue for flights to London):

SELECT 
    AP.City AS DestinationCity,
    AP.Country,
    COUNT(DISTINCT R.ResrNo) AS TotalReservations,
    COUNT(DISTINCT RP.Id) AS TotalPassengers,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    AVG(R.TotalFare) AS AverageFare
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport AP ON L.ArrAirportID = AP.Id
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
WHERE AP.City = 'London'
GROUP BY AP.City, AP.Country;

-- Expected Output:
-- +------------------+----------------+-------------------+-----------------+--------------+-------------------+-------------+
-- | DestinationCity  | Country        | TotalReservations | TotalPassengers | TotalRevenue | TotalBookingFees  | AverageFare |
-- +------------------+----------------+-------------------+-----------------+--------------+-------------------+-------------+
-- | London           | United Kingdom |                 1 |               1 |       500.00 |             50.00 |      500.00 |
-- +------------------+----------------+-------------------+-----------------+--------------+-------------------+-------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Considers final destination of each leg. A multi-leg journey contributes to
-- multiple destination cities. Useful for destination marketing analysis.

-- ============================================================================
-- TRANSACTION 3.1.7c: Revenue Generated by a Particular Customer
-- ============================================================================

-- Definition:
-- Calculate total revenue from a specific customer (lifetime value)

-- Input Parameters:
--   @AccountNo INTEGER - Customer account number

-- SQL Statement (Parameterized):
/*
SELECT 
    C.AccountNo,
    P.FirstName,
    P.LastName,
    C.Email,
    C.Rating,
    COUNT(R.ResrNo) AS TotalReservations,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    AVG(R.TotalFare) AS AverageFare,
    MIN(R.ResrDate) AS FirstReservation,
    MAX(R.ResrDate) AS LastReservation
FROM Customer C
JOIN Person P ON C.Id = P.Id
LEFT JOIN Reservation R ON C.AccountNo = R.AccountNo
WHERE C.AccountNo = ?
GROUP BY C.AccountNo, P.FirstName, P.LastName, C.Email, C.Rating;
*/

-- Execution Example (Revenue from John Doe, Account 222):

SELECT 
    C.AccountNo,
    P.FirstName,
    P.LastName,
    C.Email,
    C.Rating,
    COUNT(R.ResrNo) AS TotalReservations,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    AVG(R.TotalFare) AS AverageFare,
    MIN(R.ResrDate) AS FirstReservation,
    MAX(R.ResrDate) AS LastReservation
FROM Customer C
JOIN Person P ON C.Id = P.Id
LEFT JOIN Reservation R ON C.AccountNo = R.AccountNo
WHERE C.AccountNo = 222
GROUP BY C.AccountNo, P.FirstName, P.LastName, C.Email, C.Rating;

-- Expected Output:
-- +-----------+-----------+----------+-------------------+--------+-------------------+--------------+-------------------+-------------+---------------------+---------------------+
-- | AccountNo | FirstName | LastName | Email             | Rating | TotalReservations | TotalRevenue | TotalBookingFees  | AverageFare | FirstReservation    | LastReservation     |
-- +-----------+-----------+----------+-------------------+--------+-------------------+--------------+-------------------+-------------+---------------------+---------------------+
-- |       222 | John      | Doe      | jdoe@woot.com     |      7 |                 1 |      1200.00 |            120.00 |     1200.00 | 2011-01-05 00:00:00 | 2011-01-05 00:00:00 |
-- +-----------+-----------+----------+-------------------+--------+-------------------+--------------+-------------------+-------------+---------------------+---------------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Shows customer lifetime value and purchase history. Rating can help identify
-- high-value customers for targeted marketing.

-- ============================================================================
-- TRANSACTION 3.1.8: Determine Which Customer Representative Generated 
--                    Most Total Revenue
-- ============================================================================

-- Definition:
-- Identify the top-performing customer representative by total revenue

-- Input Parameters: None

-- SQL Statement:

SELECT 
    E.SSN,
    P.FirstName,
    P.LastName,
    P.Phone,
    COUNT(R.ResrNo) AS TotalReservations,
    SUM(R.TotalFare) AS TotalRevenue,
    SUM(R.BookingFee) AS TotalBookingFees,
    AVG(R.TotalFare) AS AverageFare
FROM Employee E
JOIN Person P ON E.Id = P.Id
LEFT JOIN Reservation R ON E.SSN = R.RepSSN
WHERE E.IsManager = FALSE
GROUP BY E.SSN, P.FirstName, P.LastName, P.Phone
ORDER BY TotalRevenue DESC
LIMIT 1;

-- Expected Output:
-- +-----------+-----------+----------+---------------+-------------------+--------------+-------------------+-------------+
-- | SSN       | FirstName | LastName | Phone         | TotalReservations | TotalRevenue | TotalBookingFees  | AverageFare |
-- +-----------+-----------+----------+---------------+-------------------+--------------+-------------------+-------------+
-- | 123456789 | Alice     | Johnson  | 631-555-0001  |                 2 |      4533.33 |            453.33 |     2266.67 |
-- +-----------+-----------+----------+---------------+-------------------+--------------+-------------------+-------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Alice Johnson handled 2 reservations (ResrNo 111 and 333) totaling $4533.33.
-- Bob Williams handled 1 reservation (ResrNo 222) totaling $500.00.
-- Useful for employee performance reviews and bonuses.

-- ============================================================================
-- TRANSACTION 3.1.9: Determine Which Customer Generated Most Total Revenue
-- ============================================================================

-- Definition:
-- Identify the highest-value customer by total spending

-- Input Parameters: None

-- SQL Statement:

SELECT 
    C.AccountNo,
    P.FirstName,
    P.LastName,
    C.Email,
    P.Phone,
    C.Rating,
    COUNT(R.ResrNo) AS TotalReservations,
    SUM(R.TotalFare) AS TotalRevenue,
    AVG(R.TotalFare) AS AverageFare,
    MAX(R.ResrDate) AS LastReservationDate
FROM Customer C
JOIN Person P ON C.Id = P.Id
LEFT JOIN Reservation R ON C.AccountNo = R.AccountNo
GROUP BY C.AccountNo, P.FirstName, P.LastName, C.Email, P.Phone, C.Rating
ORDER BY TotalRevenue DESC
LIMIT 1;

-- Expected Output:
-- +-----------+-----------+----------+-------------------------+--------------+--------+-------------------+--------------+-------------+---------------------+
-- | AccountNo | FirstName | LastName | Email                   | Phone        | Rating | TotalReservations | TotalRevenue | AverageFare | LastReservationDate |
-- +-----------+-----------+----------+-------------------------+--------------+--------+-------------------+--------------+-------------+---------------------+
-- |       333 | Rick      | Astley   | rickroller@rolld.com    | 314-159-2653 |     10 |                 1 |      3333.33 |     3333.33 | 2011-01-13 00:00:00 |
-- +-----------+-----------+----------+-------------------------+--------------+--------+-------------------+--------------+-------------+---------------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Rick Astley is the top customer with $3333.33 total revenue. Customer rating (10)
-- also indicates high value. Useful for VIP customer programs.

-- ============================================================================
-- TRANSACTION 3.1.10: Produce List of Most Active Flights
-- ============================================================================

-- Definition:
-- List flights by number of reservations (activity level), showing popularity

-- Input Parameters:
--   @Limit INTEGER - Number of top flights to return (optional, default 10)

-- SQL Statement (Parameterized):
/*
SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    GROUP_CONCAT(
        CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
        ORDER BY L.LegNo 
        SEPARATOR ', '
    ) AS Route,
    COUNT(DISTINCT I.ResrNo) AS TotalReservations,
    COUNT(DISTINCT RP.Id) AS TotalPassengers,
    F.NoOfSeats,
    ROUND(COUNT(DISTINCT RP.Id) * 100.0 / F.NoOfSeats, 2) AS OccupancyRate
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
LEFT JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
LEFT JOIN Includes I ON F.AirlineID = I.AirlineID AND F.FlightNo = I.FlightNo
LEFT JOIN Reservation R ON I.ResrNo = R.ResrNo
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats
ORDER BY TotalReservations DESC, TotalPassengers DESC
LIMIT ?;
*/

-- Execution Example (Get top 10 most active flights):

SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    GROUP_CONCAT(
        CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
        ORDER BY L.LegNo 
        SEPARATOR ', '
    ) AS Route,
    COUNT(DISTINCT I.ResrNo) AS TotalReservations,
    COUNT(DISTINCT RP.Id) AS TotalPassengers,
    F.NoOfSeats,
    ROUND(COUNT(DISTINCT RP.Id) * 100.0 / F.NoOfSeats, 2) AS OccupancyRate
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
LEFT JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
LEFT JOIN Includes I ON F.AirlineID = I.AirlineID AND F.FlightNo = I.FlightNo
LEFT JOIN Reservation R ON I.ResrNo = R.ResrNo
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats
ORDER BY TotalReservations DESC, TotalPassengers DESC
LIMIT 10;

-- Expected Output:
-- +-----------+-------------------+----------+----------------------+-------------------+-----------------+-----------+--------------+
-- | AirlineID | AirlineName       | FlightNo | Route                | TotalReservations | TotalPassengers | NoOfSeats | OccupancyRate|
-- +-----------+-------------------+----------+----------------------+-------------------+-----------------+-----------+--------------+
-- | AA        | American Airlines |      111 | LGA->LAX, LAX->HND   |                 1 |               1 |       100 |         1.00 |
-- | AM        | Air Madagascar    |     1337 | JFK->TNR             |                 1 |               1 |        33 |         3.03 |
-- | JB        | JetBlue Airways   |      111 | SFO->BOS, BOS->LHR   |                 1 |               1 |       150 |         0.67 |
-- +-----------+-------------------+----------+----------------------+-------------------+-----------------+-----------+--------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- All demo flights have 1 reservation each. OccupancyRate shows % of seats filled.
-- In production with more data, this would identify truly popular routes.

-- ============================================================================
-- TRANSACTION 3.1.11: Produce List of All Customers Who Have Seats Reserved 
--                     on a Given Flight
-- ============================================================================

-- Definition:
-- List all passengers with seat assignments for a specific flight and date

-- Input Parameters:
--   @AirlineID CHAR(2)  - Airline code
--   @FlightNo  INTEGER  - Flight number
--   @Date      DATE     - Flight date

-- SQL Statement (Parameterized):
/*
SELECT 
    P.FirstName,
    P.LastName,
    P.Phone,
    C.Email,
    C.AccountNo,
    RP.SeatNo,
    RP.Class,
    RP.Meal,
    R.ResrNo,
    R.TotalFare
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Passenger PS ON RP.Id = PS.Id AND RP.AccountNo = PS.AccountNo
JOIN Person P ON PS.Id = P.Id
JOIN Customer C ON PS.AccountNo = C.AccountNo
WHERE I.AirlineID = ? 
  AND I.FlightNo = ?
  AND I.Date = ?
ORDER BY RP.Class DESC, RP.SeatNo;
*/

-- Execution Example (Passengers on AA Flight 111 on January 5, 2011):

SELECT 
    P.FirstName,
    P.LastName,
    P.Phone,
    C.Email,
    C.AccountNo,
    RP.SeatNo,
    RP.Class,
    RP.Meal,
    R.ResrNo,
    R.TotalFare
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Passenger PS ON RP.Id = PS.Id AND RP.AccountNo = PS.AccountNo
JOIN Person P ON PS.Id = P.Id
JOIN Customer C ON PS.AccountNo = C.AccountNo
WHERE I.AirlineID = 'AA' 
  AND I.FlightNo = 111
  AND I.Date = '2011-01-05'
ORDER BY RP.Class DESC, RP.SeatNo;

-- Expected Output:
-- +-----------+----------+--------------+-------------------+-----------+--------+---------+-------+--------+-----------+
-- | FirstName | LastName | Phone        | Email             | AccountNo | SeatNo | Class   | Meal  | ResrNo | TotalFare |
-- +-----------+----------+--------------+-------------------+-----------+--------+---------+-------+--------+-----------+
-- | John      | Doe      | 123-123-1234 | jdoe@woot.com     |       222 | 33F    | Economy | Chips |    111 |   1200.00 |
-- +-----------+----------+--------------+-------------------+-----------+--------+---------+-------+--------+-----------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- Useful for flight manifests, meal planning, and customer service. Sorted by
-- class (First, Business, Economy) then seat number.

-- ============================================================================
-- TRANSACTION 3.1.12: Produce List of All Flights for a Given Airport
-- ============================================================================

-- Definition:
-- List all departing and arriving flights for a specific airport

-- Input Parameters:
--   @AirportID CHAR(3) - Airport code (e.g., 'JFK')

-- SQL Statement (Parameterized):
/*
-- Departing flights
SELECT 
    'Departure' AS FlightType,
    L.AirlineID,
    A.Name AS AirlineName,
    L.FlightNo,
    L.LegNo,
    L.DepTime AS ScheduledTime,
    L.DepAirportID AS ThisAirport,
    L.ArrAirportID AS OtherAirport,
    AP.City AS OtherCity,
    AP.Country AS OtherCountry
FROM Leg L
JOIN Airline A ON L.AirlineID = A.Id
JOIN Airport AP ON L.ArrAirportID = AP.Id
WHERE L.DepAirportID = ?

UNION

-- Arriving flights
SELECT 
    'Arrival' AS FlightType,
    L.AirlineID,
    A.Name AS AirlineName,
    L.FlightNo,
    L.LegNo,
    L.ArrTime AS ScheduledTime,
    L.ArrAirportID AS ThisAirport,
    L.DepAirportID AS OtherAirport,
    AP.City AS OtherCity,
    AP.Country AS OtherCountry
FROM Leg L
JOIN Airline A ON L.AirlineID = A.Id
JOIN Airport AP ON L.DepAirportID = AP.Id
WHERE L.ArrAirportID = ?

ORDER BY ScheduledTime, FlightType;
*/

-- Execution Example (All flights for JFK airport):

SELECT 
    'Departure' AS FlightType,
    L.AirlineID,
    A.Name AS AirlineName,
    L.FlightNo,
    L.LegNo,
    L.DepTime AS ScheduledTime,
    L.DepAirportID AS ThisAirport,
    L.ArrAirportID AS OtherAirport,
    AP.City AS OtherCity,
    AP.Country AS OtherCountry
FROM Leg L
JOIN Airline A ON L.AirlineID = A.Id
JOIN Airport AP ON L.ArrAirportID = AP.Id
WHERE L.DepAirportID = 'JFK'

UNION

SELECT 
    'Arrival' AS FlightType,
    L.AirlineID,
    A.Name AS AirlineName,
    L.FlightNo,
    L.LegNo,
    L.ArrTime AS ScheduledTime,
    L.ArrAirportID AS ThisAirport,
    L.DepAirportID AS OtherAirport,
    AP.City AS OtherCity,
    AP.Country AS OtherCountry
FROM Leg L
JOIN Airline A ON L.AirlineID = A.Id
JOIN Airport AP ON L.DepAirportID = AP.Id
WHERE L.ArrAirportID = 'JFK'

ORDER BY ScheduledTime, FlightType;

-- Expected Output:
-- +------------+-----------+----------------+----------+-------+---------------------+-------------+--------------+---------------+-----------------+
-- | FlightType | AirlineID | AirlineName    | FlightNo | LegNo | ScheduledTime       | ThisAirport | OtherAirport | OtherCity     | OtherCountry    |
-- +------------+-----------+----------------+----------+-------+---------------------+-------------+--------------+---------------+-----------------+
-- | Departure  | AM        | Air Madagascar |     1337 |     1 | 2011-01-13 07:00:00 | JFK         | TNR          | Antananarivo  | Madagascar      |
-- +------------+-----------+----------------+----------+-------+---------------------+-------------+--------------+---------------+-----------------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- JFK only has one flight in demo data (Air Madagascar departing to TNR).
-- UNION combines departures and arrivals into one result set.

-- ============================================================================
-- TRANSACTION 3.1.13: Produce List of Flights Whose Arrival and Departure 
--                     Times Are On-Time/Delayed
-- ============================================================================

-- Definition:
-- List flight status (on-time or delayed)

-- Input Parameters:
--   @Status VARCHAR(20) - Filter by status ('On-Time', 'Delayed', or NULL for all)

-- SQL Statement (Parameterized):
-- NOTE: This requires a Status field in the Leg table which is NOT in the
--       current schema. This query assumes all flights are on-time.
/*
SELECT 
    L.AirlineID,
    A.Name AS AirlineName,
    L.FlightNo,
    L.LegNo,
    L.DepAirportID,
    AP_DEP.City AS DepartureCity,
    L.ArrAirportID,
    AP_ARR.City AS ArrivalCity,
    L.DepTime AS ScheduledDeparture,
    L.ArrTime AS ScheduledArrival,
    'On-Time' AS Status
FROM Leg L
JOIN Airline A ON L.AirlineID = A.Id
JOIN Airport AP_DEP ON L.DepAirportID = AP_DEP.Id
JOIN Airport AP_ARR ON L.ArrAirportID = AP_ARR.Id
WHERE (? IS NULL OR 'On-Time' = ?)
ORDER BY L.DepTime;
*/

-- Execution Example (List all flights - all assumed on-time):

SELECT 
    L.AirlineID,
    A.Name AS AirlineName,
    L.FlightNo,
    L.LegNo,
    L.DepAirportID,
    AP_DEP.City AS DepartureCity,
    L.ArrAirportID,
    AP_ARR.City AS ArrivalCity,
    L.DepTime AS ScheduledDeparture,
    L.ArrTime AS ScheduledArrival,
    'On-Time' AS Status
FROM Leg L
JOIN Airline A ON L.AirlineID = A.Id
JOIN Airport AP_DEP ON L.DepAirportID = AP_DEP.Id
JOIN Airport AP_ARR ON L.ArrAirportID = AP_ARR.Id
ORDER BY L.DepTime;

-- Expected Output:
-- +-----------+-------------------+----------+-------+--------------+---------------+--------------+-------------+---------------------+---------------------+---------+
-- | AirlineID | AirlineName       | FlightNo | LegNo | DepAirportID | DepartureCity | ArrAirportID | ArrivalCity | ScheduledDeparture  | ScheduledArrival    | Status  |
-- +-----------+-------------------+----------+-------+--------------+---------------+--------------+-------------+---------------------+---------------------+---------+
-- | AA        | American Airlines |      111 |     1 | LGA          | New York      | LAX          | Los Angeles | 2011-01-05 11:00:00 | 2011-01-05 17:00:00 | On-Time |
-- | AA        | American Airlines |      111 |     2 | LAX          | Los Angeles   | HND          | Tokyo       | 2011-01-05 19:00:00 | 2011-01-06 07:30:00 | On-Time |
-- | JB        | JetBlue Airways   |      111 |     1 | SFO          | San Francisco | BOS          | Boston      | 2011-01-10 14:00:00 | 2011-01-10 19:30:00 | On-Time |
-- | JB        | JetBlue Airways   |      111 |     2 | BOS          | Boston        | LHR          | London      | 2011-01-10 22:30:00 | 2011-01-11 05:00:00 | On-Time |
-- | AM        | Air Madagascar    |     1337 |     1 | JFK          | New York      | TNR          | Antananarivo| 2011-01-13 07:00:00 | 2011-01-14 03:00:00 | On-Time |
-- +-----------+-------------------+----------+-------+--------------+---------------+--------------+-------------+---------------------+---------------------+---------+

-- [PASTE YOUR ACTUAL OUTPUT HERE]


-- Notes:
-- THIS TRANSACTION REQUIRES SCHEMA MODIFICATION to fully implement. 
-- The current schema does not include a Status field in the Leg table.
-- To fully implement, add: ALTER TABLE Leg ADD COLUMN Status VARCHAR(20) DEFAULT 'On-Time';
-- For demo purposes, all flights are assumed on-time.

-- ============================================================================
-- END OF MANAGER-LEVEL TRANSACTIONS (13/13 COMPLETED)
-- ============================================================================

-- Next: Complete Customer Representative-Level (Section 3.2) and 
--       Customer-Level (Section 3.3) transactions

-- ============================================================================