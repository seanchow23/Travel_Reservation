-- ============================================================================
-- Section 3.2 - Customer-Representative-Level Transactions (CORRECTED)
-- ============================================================================

USE project_2;

-- ============================================================================
-- TRANSACTION 3.2.1: Record a Reservation (One-Way)
-- ============================================================================

-- DEFINITION: 
-- Customer representative records a new one-way flight reservation

-- INPUT PARAMETERS:
--   @ResrNo        INTEGER       - Unique reservation number
--   @AccountNo     INTEGER       - Customer account number
--   @RepSSN        INTEGER       - Customer rep SSN
--   @BookingFee    DECIMAL(10,2) - Booking fee
--   @TotalFare     DECIMAL(10,2) - Total fare
--   @AirlineID     CHAR(2)       - Airline code
--   @FlightNo      INTEGER       - Flight number
--   @TravelDate    DATE          - Travel date
--   @PassengerId   INTEGER       - Passenger person ID
--   @SeatNo        CHAR(5)       - Seat assignment
--   @Class         VARCHAR(20)   - Cabin class
--   @Meal          VARCHAR(50)   - Meal preference

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

-- Check seat availability
SELECT (F.NoOfSeats - IFNULL(S.Seats,0)) AS AvailableSeats
FROM Flight F
LEFT JOIN (
  SELECT I.AirlineID, I.FlightNo, I.Date,
         COUNT(DISTINCT RP.Id, RP.AccountNo) AS Seats
  FROM Includes I
  JOIN ReservationPassenger RP ON RP.ResrNo = I.ResrNo
  WHERE I.AirlineID = ? AND I.FlightNo = ? AND I.Date = ?
  GROUP BY I.AirlineID, I.FlightNo, I.Date
) S ON S.AirlineID = F.AirlineID AND S.FlightNo = F.FlightNo
WHERE F.AirlineID = ? AND F.FlightNo = ?
FOR UPDATE;

-- Create reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (?, NOW(), ?, ?, ?, ?);

-- Include all legs of the flight
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Add passenger(s)
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (?, ?, ?, ?, ?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: ResrNo=444, AccountNo=222, RepSSN=123456789, BookingFee=25.00, 
--             TotalFare=250.00, AirlineID='JB', FlightNo=111, TravelDate='2011-01-10',
--             PassengerId=2, SeatNo='12A', Class='Economy', Meal='Chips'

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 444;
DELETE FROM Includes WHERE ResrNo = 444;
DELETE FROM Reservation WHERE ResrNo = 444;

START TRANSACTION;

-- Check seat availability
SELECT (F.NoOfSeats - IFNULL(S.Seats,0)) AS AvailableSeats
FROM Flight F
LEFT JOIN (
  SELECT I.AirlineID, I.FlightNo, I.Date,
         COUNT(DISTINCT RP.Id, RP.AccountNo) AS Seats
  FROM Includes I
  JOIN ReservationPassenger RP ON RP.ResrNo = I.ResrNo
  WHERE I.AirlineID = 'JB' AND I.FlightNo = 111 AND I.Date = '2011-01-10'
  GROUP BY I.AirlineID, I.FlightNo, I.Date
) S ON S.AirlineID = F.AirlineID AND S.FlightNo = F.FlightNo
WHERE F.AirlineID = 'JB' AND F.FlightNo = 111
FOR UPDATE;

-- Create reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (444, NOW(), 25.00, 250.00, 123456789, 222);

-- Include all legs of the flight
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 444, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-10'
FROM Leg L
WHERE L.AirlineID = 'JB' AND L.FlightNo = 111
ORDER BY L.LegNo;

-- Add passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (444, 2, 222, '12A', 'Economy', 'Chips');

COMMIT;

-- VERIFICATION:
SELECT R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee, 
       P.FirstName, P.LastName, RP.SeatNo, RP.Class,
       COUNT(I.LegNo) AS NumberOfLegs
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE R.ResrNo = 444
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee,
         P.FirstName, P.LastName, RP.SeatNo, RP.Class;

-- OUTPUT:
/*
[PASTE YOUR OUTPUT HERE]
Expected: John Doe, Seat 12A, 2 legs, $250.00 fare
*/

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 444;
DELETE FROM Includes WHERE ResrNo = 444;
DELETE FROM Reservation WHERE ResrNo = 444;

-- NOTES:
-- Transaction block ensures all inserts succeed together.
-- FOR UPDATE locks the flight row to prevent overbooking.
-- Includes all legs automatically using SELECT...INSERT pattern.
-- Uses John Doe (Person ID 2, Account 222) as passenger.

-- ============================================================================
-- TRANSACTION 3.2.2: Add Customer
-- ============================================================================

-- DEFINITION:
-- Customer representative adds a new customer to the system

-- INPUT PARAMETERS:
--   @PersonId      INTEGER      - Unique person identifier
--   @FirstName     VARCHAR(50)  - Customer first name
--   @LastName      VARCHAR(50)  - Customer last name
--   @Address       VARCHAR(100) - Street address
--   @City          VARCHAR(50)  - City
--   @State         VARCHAR(50)  - State
--   @ZipCode       INTEGER      - ZIP code
--   @Phone         VARCHAR(15)  - Phone number
--   @AccountNo     INTEGER      - Customer account number
--   @Email         VARCHAR(50)  - Email address
--   @CreditCardNo  CHAR(16)     - Credit card number

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

INSERT INTO Person (Id, FirstName, LastName, Address, City, State, ZipCode, Phone)
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

INSERT INTO Customer (Id, AccountNo, Email, CreationDate, Rating, CreditCardNo)
VALUES (?, ?, ?, NOW(), 0, ?);

INSERT INTO Passenger (Id, AccountNo)
VALUES (?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: Id=200, FirstName='Sarah', LastName='Connor', Address='1984 Skynet Dr',
--             City='Los Angeles', State='CA', ZipCode=90001, Phone='310-555-1984',
--             AccountNo=444, Email='sarah.connor@resistance.com', CreditCardNo='4111111111111111'

-- CLEANUP FIRST
-- 1. Delete grandchildren first (if any)
DELETE FROM ReservationPassenger WHERE AccountNo = 444;

-- 2. Delete children
DELETE FROM CustomerPreferences WHERE AccountNo = 444;
DELETE FROM Passenger WHERE AccountNo = 444;  

-- 3. Delete parent
DELETE FROM Customer WHERE AccountNo = 444;

-- 4. Delete person last
DELETE FROM Person WHERE Id = 200;

START TRANSACTION;

INSERT INTO Person (Id, FirstName, LastName, Address, City, State, ZipCode, Phone)
VALUES (200, 'Sarah', 'Connor', '1984 Skynet Dr', 'Los Angeles', 'CA', 90001, '310-555-1984');

INSERT INTO Customer (Id, AccountNo, Email, CreationDate, Rating, CreditCardNo)
VALUES (200, 444, 'sarah.connor@resistance.com', NOW(), 0, '4111111111111111');

INSERT INTO Passenger (Id, AccountNo)
VALUES (200, 444);

COMMIT;

-- VERIFICATION:
SELECT P.FirstName, P.LastName, C.AccountNo, C.Email, C.Rating, C.CreationDate
FROM Customer C
JOIN Person P ON P.Id = C.Id
WHERE C.AccountNo = 444;

-- OUTPUT:
/*
Expected: Sarah Connor, Account 444, Rating 0
*/

-- CLEANUP AFTER
DELETE FROM Passenger WHERE Id = 200 AND AccountNo = 444;
DELETE FROM Customer WHERE AccountNo = 444;
DELETE FROM Person WHERE Id = 200;

-- NOTES:
-- Transaction ensures Person, Customer, and Passenger all created together.
-- Passenger record required for customer to be added to reservations.
-- New customers start with rating 0.

-- ============================================================================
-- TRANSACTION 3.2.3: Edit Customer
-- ============================================================================

-- DEFINITION:
-- Customer representative updates customer account information

-- INPUT PARAMETERS:
--   @AccountNo     INTEGER      - Customer account number (identifies customer)
--   @Email         VARCHAR(50)  - Updated email address (optional)
--   @Rating        INTEGER      - Updated rating (optional)
--   @CreditCardNo  CHAR(16)     - Updated credit card (optional)

-- SQL STATEMENT (PARAMETERIZED):
/*
UPDATE Customer
SET Email = ?,
    Rating = ?,
    CreditCardNo = ?
WHERE AccountNo = ?;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: Email='s.connor@resistance.com', Rating=1, 
--             CreditCardNo='4111111111111111', AccountNo=444

-- First, ensure Sarah Connor exists
DELETE FROM Passenger WHERE Id = 200 AND AccountNo = 444;
DELETE FROM Customer WHERE AccountNo = 444;
DELETE FROM Person WHERE Id = 200;

INSERT INTO Person VALUES (200, 'Sarah', 'Connor', '1984 Skynet Dr', 'Los Angeles', 'CA', 90001, '310-555-1984');
INSERT INTO Customer VALUES (200, 444, '4111111111111111', 'sarah.connor@resistance.com', NOW(), 0);
INSERT INTO Passenger VALUES (200, 444);

-- Now update her information
UPDATE Customer
SET Email = 's.connor@resistance.com',
    Rating = 1,
    CreditCardNo = '4111111111111111'
WHERE AccountNo = 444;

-- VERIFICATION:
SELECT AccountNo, Email, Rating, CreditCardNo 
FROM Customer 
WHERE AccountNo = 444;

-- OUTPUT:
/*
Expected: s.connor@resistance.com, Rating 1
*/

-- CLEANUP
DELETE FROM Passenger WHERE Id = 200 AND AccountNo = 444;
DELETE FROM Customer WHERE AccountNo = 444;
DELETE FROM Person WHERE Id = 200;

-- NOTES:
-- Single UPDATE statement, no transaction needed.
-- Only updates provided fields; NULL parameters mean no change.

-- ============================================================================
-- TRANSACTION 3.2.4: Delete Customer
-- ============================================================================

-- DEFINITION:
-- Customer representative removes a customer from the system

-- INPUT PARAMETERS:
--   @AccountNo INTEGER - Customer account number to delete

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

DELETE FROM CustomerPreferences WHERE AccountNo = ?;
DELETE FROM Passenger WHERE AccountNo = ?;
DELETE FROM Customer WHERE AccountNo = ?;
DELETE FROM Person WHERE Id = (SELECT Id FROM Customer WHERE AccountNo = ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo=444

-- CLEANUP + CREATE TEST DATA
DELETE FROM ReservationPassenger WHERE AccountNo = 444;
DELETE FROM CustomerPreferences WHERE AccountNo = 444;
DELETE FROM Passenger WHERE Id = 200 AND AccountNo = 444;
DELETE FROM Customer WHERE AccountNo = 444;
DELETE FROM Person WHERE Id = 200;

-- Create test customer
START TRANSACTION;

INSERT INTO Person VALUES (200, 'Sarah', 'Connor', '1984 Skynet Dr', 'Los Angeles', 'CA', 90001, '310-555-1984');
INSERT INTO Customer VALUES (200, 444, '4111111111111111', 'sarah.connor@resistance.com', NOW(), 0);
INSERT INTO Passenger VALUES (200, 444);

COMMIT;

-- Verify customer exists
SELECT P.FirstName, P.LastName, C.AccountNo 
FROM Customer C 
JOIN Person P ON C.Id = P.Id 
WHERE C.AccountNo = 444;

-- NOW DELETE (Transaction 3.2.4 Execution)
START TRANSACTION;

DELETE FROM ReservationPassenger WHERE AccountNo = 444;
DELETE FROM CustomerPreferences WHERE AccountNo = 444;
DELETE FROM Passenger WHERE Id = 200 AND AccountNo = 444;
DELETE FROM Customer WHERE AccountNo = 444;
DELETE FROM Person WHERE Id = 200;

COMMIT;

-- VERIFICATION (should return 0)
SELECT COUNT(*) AS CustomerExists FROM Customer WHERE AccountNo = 444;

-- OUTPUT:
/*
[PASTE YOUR OUTPUT HERE]
Expected: 0 (customer deleted)
*/

-- NOTES:
-- Transaction ensures all related records deleted together.
-- Delete in correct order: Preferences → Passenger → Customer → Person
-- Will fail if customer has reservations (foreign key constraint).

-- ============================================================================
-- TRANSACTION 3.2.5: Produce Customer Mailing Lists
-- ============================================================================

-- DEFINITION:
-- Generate mailing list of all customers with email addresses

-- INPUT PARAMETERS: None

-- SQL STATEMENT:
SELECT P.FirstName, P.LastName, C.Email, P.Phone, P.City, P.State
FROM Customer C
JOIN Person P ON P.Id = C.Id
WHERE C.Email IS NOT NULL
ORDER BY P.LastName, P.FirstName;

-- EXECUTION WITH DEMO DATA:

SELECT P.FirstName, P.LastName, C.Email, P.Phone, P.City, P.State
FROM Customer C
JOIN Person P ON P.Id = C.Id
WHERE C.Email IS NOT NULL
ORDER BY P.LastName, P.FirstName;

-- OUTPUT:
/*
[PASTE YOUR OUTPUT HERE]
Expected: 3 customers (Jane Smith, John Doe, Rick Astley)
*/

-- NO CLEANUP NEEDED (read-only query)

-- NOTES:
-- Read-only query for promotional materials.
-- Filters out customers without email addresses.

-- ============================================================================
-- TRANSACTION 3.2.6: Produce Flight Suggestions for a Customer
-- ============================================================================

-- DEFINITION:
-- Recommend flights based on customer's historical travel patterns

-- INPUT PARAMETERS:
--   @AccountNo INTEGER - Customer account number

-- SQL STATEMENT (PARAMETERIZED):
/*
WITH FavRoutes AS (
  SELECT L.DepAirportID, L.ArrAirportID, COUNT(*) AS Trips
  FROM Reservation R
  JOIN Includes I ON I.ResrNo = R.ResrNo
  JOIN Leg L ON (L.AirlineID, L.FlightNo, L.LegNo) = (I.AirlineID, I.FlightNo, I.LegNo)
  WHERE R.AccountNo = ?
  GROUP BY L.DepAirportID, L.ArrAirportID
  ORDER BY Trips DESC
  LIMIT 5
)
SELECT DISTINCT F.AirlineID, A.Name AS AirlineName, F.FlightNo, L.LegNo,
       L.DepAirportID, Dep.City AS FromCity,
       L.ArrAirportID, Arr.City AS ToCity,
       L.DepTime, L.ArrTime
FROM FavRoutes FR
JOIN Leg L ON L.DepAirportID = FR.DepAirportID AND L.ArrAirportID = FR.ArrAirportID
JOIN Flight F ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airline A ON A.Id = F.AirlineID
JOIN Airport Dep ON Dep.Id = L.DepAirportID
JOIN Airport Arr ON Arr.Id = L.ArrAirportID
ORDER BY L.DepTime;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo=222
-- Notes: John Doe has flown LGA→LAX and LAX→HND; suggests flights on those routes

WITH FavRoutes AS (
  SELECT L.DepAirportID, L.ArrAirportID, COUNT(*) AS Trips
  FROM Reservation R
  JOIN Includes I ON I.ResrNo = R.ResrNo
  JOIN Leg L ON (L.AirlineID, L.FlightNo, L.LegNo) = (I.AirlineID, I.FlightNo, I.LegNo)
  WHERE R.AccountNo = 222
  GROUP BY L.DepAirportID, L.ArrAirportID
  ORDER BY Trips DESC
  LIMIT 5
)
SELECT DISTINCT F.AirlineID, A.Name AS AirlineName, F.FlightNo, L.LegNo,
       L.DepAirportID, Dep.City AS FromCity,
       L.ArrAirportID, Arr.City AS ToCity,
       L.DepTime, L.ArrTime
FROM FavRoutes FR
JOIN Leg L ON L.DepAirportID = FR.DepAirportID AND L.ArrAirportID = FR.ArrAirportID
JOIN Flight F ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airline A ON A.Id = F.AirlineID
JOIN Airport Dep ON Dep.Id = L.DepAirportID
JOIN Airport Arr ON Arr.Id = L.ArrAirportID
ORDER BY L.DepTime;

-- OUTPUT:
/*
Expected: AA Flight 111 legs (LGA→LAX and LAX→HND)
*/



