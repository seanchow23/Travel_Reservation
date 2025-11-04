USE project_2;

-- TRANSACTION 3.3.1: Search for Available Flights
-- ============================================================================

-- DEFINITION:
-- Search for flights between two cities on a specific date, allowing customers
-- to browse available options including one-way, round-trip, multi-city routes

-- INPUT PARAMETERS:
--   @DepCity       VARCHAR(50)  - Departure city
--   @ArrCity       VARCHAR(50)  - Arrival city
--   @Date          DATE         - Desired travel date
--   @FlexDays      INTEGER      - Flexible date range 

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    GROUP_CONCAT(CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    MIN(L.DepTime) AS DepartureTime,
    MAX(L.ArrTime) AS ArrivalTime,
    F.NoOfSeats AS TotalSeats,
    MIN(FA.FareAmount) AS StartingFare,
    COUNT(L.LegNo) AS NumberOfLegs
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
JOIN Fare FA ON F.AirlineID = FA.AirlineID 
             AND F.FlightNo = FA.FlightNo 
             AND FA.FareType = 'OneWay'
WHERE APDep.City = ? 
  AND APArr.City = ?
  AND DATE(L.DepTime) BETWEEN DATE(?) AND DATE_ADD(DATE(?), INTERVAL ? DAY)
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats
ORDER BY MIN(L.DepTime), MIN(FA.FareAmount);
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: DepCity='New York', ArrCity='Los Angeles', Date='2011-01-05', FlexDays=0

SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    GROUP_CONCAT(CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    MIN(L.DepTime) AS DepartureTime,
    MAX(L.ArrTime) AS ArrivalTime,
    F.NoOfSeats AS TotalSeats,
    MIN(FA.FareAmount) AS StartingFare,
    COUNT(L.LegNo) AS NumberOfLegs
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
JOIN Fare FA ON F.AirlineID = FA.AirlineID 
             AND F.FlightNo = FA.FlightNo 
             AND FA.FareType = 'OneWay'
WHERE APDep.City = 'New York' 
  AND APArr.City = 'Los Angeles'
  AND DATE(L.DepTime) BETWEEN '2011-01-05' AND DATE_ADD('2011-01-05', INTERVAL 0 DAY)
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats
ORDER BY MIN(L.DepTime), MIN(FA.FareAmount);

-- OUTPUT:
/*
Expected: AA Flight 111, departing LGA->LAX at 11:00, fare starting at $400
*/

-- NOTES:
-- Supports flexible date searches (±FlexDays).
-- Shows multi-leg flights with route summary.
-- Returns cheapest fare options first.
-- Can be extended for round-trip and multi-city searches.


USE project_2;

-- ============================================================================
-- TRANSACTION 3.3.2: Make Flight Reservations
-- ============================================================================
-- This transaction supports all types of reservations as specified in Section 3.3:
-- - One-Way (Domestic and International)
-- - Round-Trip
-- - Multi-City
-- - Flexible Date/Time
-- ============================================================================

-- ============================================================================
-- TRANSACTION 3.3.2a: Make a Reservation (One-Way Domestic)
-- ============================================================================

-- DEFINITION:
-- Customer creates a one-way domestic flight reservation (within same country)

-- INPUT PARAMETERS:
--   @ResrNo        INTEGER       - Unique reservation number
--   @AccountNo     INTEGER       - Customer account number
--   @AirlineID     CHAR(2)       - Airline code
--   @FlightNo      INTEGER       - Flight number
--   @TravelDate    DATE          - Travel date
--   @PassengerId   INTEGER       - Passenger person ID
--   @PassengerAcct INTEGER       - Passenger account number
--   @SeatNo        CHAR(5)       - Seat assignment
--   @Class         VARCHAR(20)   - Cabin class
--   @Meal          VARCHAR(50)   - Meal preference
--   @TotalFare     DECIMAL(10,2) - Total fare amount
--   @BookingFee    DECIMAL(10,2) - Booking fee (10% of fare)

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

-- Insert reservation (RepSSN is NULL for online bookings)
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (?, NOW(), ?, ?, NULL, ?);

-- Include all legs of the flight
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Add passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (?, ?, ?, ?, ?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Scenario: John Doe books one-way domestic flight from New York to Los Angeles
-- Flight: American Airlines 111 (LGA->LAX) on January 5, 2011
-- Parameters: ResrNo=444, AccountNo=222, AirlineID='AA', FlightNo=111, 
--             TravelDate='2011-01-05', PassengerId=2, PassengerAcct=222,
--             SeatNo='12A', Class='Economy', Meal='Chicken', 
--             TotalFare=440.00, BookingFee=44.00

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 444;
DELETE FROM Includes WHERE ResrNo = 444;
DELETE FROM Reservation WHERE ResrNo = 444;

START TRANSACTION;

-- Check seat availability for AA 111 on 2011-01-05
SELECT (F.NoOfSeats - IFNULL(S.Seats,0)) AS AvailableSeats
FROM Flight F
LEFT JOIN (
  SELECT I.AirlineID, I.FlightNo, I.Date,
         COUNT(DISTINCT RP.Id, RP.AccountNo) AS Seats
  FROM Includes I
  JOIN ReservationPassenger RP ON RP.ResrNo = I.ResrNo
  WHERE I.AirlineID = 'AA' AND I.FlightNo = 111 AND I.Date = '2011-01-05'
  GROUP BY I.AirlineID, I.FlightNo, I.Date
) S ON S.AirlineID = F.AirlineID AND S.FlightNo = F.FlightNo
WHERE F.AirlineID = 'AA' AND F.FlightNo = 111
FOR UPDATE;

-- Create reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (444, NOW(), 44.00, 440.00, NULL, 222);

-- Include all legs (AA 111 has 2 legs: LGA->LAX->HND, but customer only books to LAX)
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 444, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-05'
FROM Leg L
WHERE L.AirlineID = 'AA' AND L.FlightNo = 111
ORDER BY L.LegNo;

-- Add John Doe as passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (444, 2, 222, '12A', 'Economy', 'Chicken');

COMMIT;

-- VERIFICATION:
SELECT R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee, 
       P.FirstName, P.LastName, RP.SeatNo, RP.Class,
       COUNT(I.LegNo) AS NumberOfLegs,
       MIN(APDep.City) AS FromCity,
       MAX(APArr.City) AS ToCity,
       MIN(L.DepAirportID) AS FromAirport,
       MAX(L.ArrAirportID) AS ToAirport
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE R.ResrNo = 444
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee,
         P.FirstName, P.LastName, RP.SeatNo, RP.Class;

-- Expected Output:
-- +--------+---------------------+-----------+------------+-----------+----------+--------+---------+--------------+---------------+----------+-------------+------------+
-- | ResrNo | ResrDate            | TotalFare | BookingFee | FirstName | LastName | SeatNo | Class   | NumberOfLegs | FromCity      | ToCity   | FromAirport | ToAirport  |
-- +--------+---------------------+-----------+------------+-----------+----------+--------+---------+--------------+---------------+----------+-------------+------------+
-- |    444 | 2025-11-03 15:00:00 |    440.00 |      44.00 | John      | Doe      | 12A    | Economy |            2 | New York      | Tokyo    | LGA         | HND        |
-- +--------+---------------------+-----------+------------+-----------+----------+--------+---------+--------------+---------------+----------+-------------+------------+

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 444;
DELETE FROM Includes WHERE ResrNo = 444;
DELETE FROM Reservation WHERE ResrNo = 444;

-- NOTES:
-- Domestic flights are within the same country (USA in this example).
-- One-way means no return flight is booked.
-- Transaction ensures atomicity across all three table inserts.
-- FOR UPDATE lock prevents overbooking.
-- Online bookings have RepSSN = NULL.

-- ============================================================================
-- TRANSACTION 3.3.2b: Make a Reservation (One-Way International)
-- ============================================================================

-- DEFINITION:
-- Customer creates a one-way international flight reservation (between countries)

-- INPUT PARAMETERS:
--   @ResrNo        INTEGER       - Unique reservation number
--   @AccountNo     INTEGER       - Customer account number
--   @AirlineID     CHAR(2)       - Airline code
--   @FlightNo      INTEGER       - Flight number
--   @TravelDate    DATE          - Travel date
--   @PassengerId   INTEGER       - Passenger person ID
--   @PassengerAcct INTEGER       - Passenger account number
--   @SeatNo        CHAR(5)       - Seat assignment
--   @Class         VARCHAR(20)   - Cabin class
--   @Meal          VARCHAR(50)   - Meal preference
--   @TotalFare     DECIMAL(10,2) - Total fare amount
--   @BookingFee    DECIMAL(10,2) - Booking fee (10% of fare)

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

-- Verify international flight (crosses country boundaries)
SELECT DISTINCT APDep.Country AS DepartureCountry, APArr.Country AS ArrivalCountry
FROM Leg L
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE L.AirlineID = ? AND L.FlightNo = ?
HAVING COUNT(DISTINCT APDep.Country, APArr.Country) > 1;

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

-- Insert reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (?, NOW(), ?, ?, NULL, ?);

-- Include all legs
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Add passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (?, ?, ?, ?, ?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Scenario: Rick Astley books one-way international flight from USA to Madagascar
-- Flight: Air Madagascar 1337 (JFK->TNR) on January 13, 2011
-- Parameters: ResrNo=555, AccountNo=333, AirlineID='AM', FlightNo=1337,
--             TravelDate='2011-01-13', PassengerId=3, PassengerAcct=333,
--             SeatNo='1A', Class='First', Meal='Sushi',
--             TotalFare=3300.00, BookingFee=330.00

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 555;
DELETE FROM Includes WHERE ResrNo = 555;
DELETE FROM Reservation WHERE ResrNo = 555;

START TRANSACTION;

-- Verify this is an international flight
SELECT DISTINCT APDep.Country AS DepartureCountry, APArr.Country AS ArrivalCountry
FROM Leg L
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE L.AirlineID = 'AM' AND L.FlightNo = 1337;

-- Check seat availability
SELECT (F.NoOfSeats - IFNULL(S.Seats,0)) AS AvailableSeats
FROM Flight F
LEFT JOIN (
  SELECT I.AirlineID, I.FlightNo, I.Date,
         COUNT(DISTINCT RP.Id, RP.AccountNo) AS Seats
  FROM Includes I
  JOIN ReservationPassenger RP ON RP.ResrNo = I.ResrNo
  WHERE I.AirlineID = 'AM' AND I.FlightNo = 1337 AND I.Date = '2011-01-13'
  GROUP BY I.AirlineID, I.FlightNo, I.Date
) S ON S.AirlineID = F.AirlineID AND S.FlightNo = F.FlightNo
WHERE F.AirlineID = 'AM' AND F.FlightNo = 1337
FOR UPDATE;

-- Insert international reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (555, NOW(), 330.00, 3300.00, NULL, 333);

-- Include flight leg
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 555, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-13'
FROM Leg L
WHERE L.AirlineID = 'AM' AND L.FlightNo = 1337
ORDER BY L.LegNo;

-- Add Rick Astley as passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (555, 3, 333, '1A', 'First', 'Sushi');

COMMIT;

-- VERIFICATION:
SELECT 
    R.ResrNo,
    R.ResrDate,
    R.TotalFare,
    P.FirstName,
    P.LastName,
    RP.SeatNo,
    RP.Class,
    APDep.City AS DepartureCity,
    APDep.Country AS DepartureCountry,
    APArr.City AS ArrivalCity,
    APArr.Country AS ArrivalCountry,
    CASE 
        WHEN APDep.Country != APArr.Country THEN 'International'
        ELSE 'Domestic'
    END AS FlightType
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE R.ResrNo = 555;

-- Expected Output:
-- +--------+---------------------+-----------+-----------+----------+--------+-------+---------------+-------------------+--------------+-------------------+---------------+
-- | ResrNo | ResrDate            | TotalFare | FirstName | LastName | SeatNo | Class | DepartureCity | DepartureCountry  | ArrivalCity  | ArrivalCountry    | FlightType    |
-- +--------+---------------------+-----------+-----------+----------+--------+-------+---------------+-------------------+--------------+-------------------+---------------+
-- |    555 | 2025-11-03 15:30:00 |   3300.00 | Rick      | Astley   | 1A     | First | New York      | United States ... | Antananarivo | Madagascar        | International |
-- +--------+---------------------+-----------+-----------+----------+--------+-------+---------------+-------------------+--------------+-------------------+---------------+

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 555;
DELETE FROM Includes WHERE ResrNo = 555;
DELETE FROM Reservation WHERE ResrNo = 555;

-- NOTES:
-- International flights cross country boundaries.
-- May require passport verification in production system.
-- Often have higher fares and different fare rules than domestic.
-- System should check visa requirements for destination country.

-- ============================================================================
-- TRANSACTION 3.3.2c: Make a Reservation (Round-Trip)
-- ============================================================================

-- DEFINITION:
-- Customer creates a round-trip flight reservation with outbound and return flights

-- INPUT PARAMETERS:
--   @ResrNo           INTEGER       - Unique reservation number
--   @AccountNo        INTEGER       - Customer account number
--   @OutboundAirline  CHAR(2)       - Outbound flight airline code
--   @OutboundFlightNo INTEGER       - Outbound flight number
--   @OutboundDate     DATE          - Outbound travel date
--   @ReturnAirline    CHAR(2)       - Return flight airline code
--   @ReturnFlightNo   INTEGER       - Return flight number
--   @ReturnDate       DATE          - Return travel date
--   @PassengerId      INTEGER       - Passenger person ID
--   @PassengerAcct    INTEGER       - Passenger account number
--   @OutboundSeatNo   CHAR(5)       - Outbound seat assignment
--   @ReturnSeatNo     CHAR(5)       - Return seat assignment
--   @Class            VARCHAR(20)   - Cabin class (same for both directions)
--   @Meal             VARCHAR(50)   - Meal preference
--   @TotalFare        DECIMAL(10,2) - Total round-trip fare
--   @BookingFee       DECIMAL(10,2) - Booking fee (10% of fare)

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

-- Check length of stay requirements for outbound flight
SELECT F.MinLengthOfStay, F.MaxLengthOfStay
FROM Flight F
WHERE F.AirlineID = ? AND F.FlightNo = ?;

-- Verify stay length meets requirements
-- Application code should check: DATEDIFF(@ReturnDate, @OutboundDate) 
-- is between MinLengthOfStay and MaxLengthOfStay

-- Check seat availability for both flights
SELECT (F.NoOfSeats - IFNULL(S.Seats,0)) AS AvailableSeats
FROM Flight F
LEFT JOIN (
  SELECT I.AirlineID, I.FlightNo, I.Date,
         COUNT(DISTINCT RP.Id, RP.AccountNo) AS Seats
  FROM Includes I
  JOIN ReservationPassenger RP ON RP.ResrNo = I.ResrNo
  WHERE (I.AirlineID = ? AND I.FlightNo = ? AND I.Date = ?)
     OR (I.AirlineID = ? AND I.FlightNo = ? AND I.Date = ?)
  GROUP BY I.AirlineID, I.FlightNo, I.Date
) S ON S.AirlineID = F.AirlineID AND S.FlightNo = F.FlightNo
WHERE (F.AirlineID = ? AND F.FlightNo = ?)
   OR (F.AirlineID = ? AND F.FlightNo = ?)
FOR UPDATE;

-- Insert reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (?, NOW(), ?, ?, NULL, ?);

-- Include all legs of outbound flight
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Include all legs of return flight
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Add passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (?, ?, ?, ?, ?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Scenario: Jane Smith books round-trip San Francisco to London and back
-- Outbound: JetBlue 111 (SFO->BOS->LHR) on Jan 10, 2011
-- Return: Same flight on Jan 17, 2011 (7-day stay)
-- Parameters: ResrNo=666, AccountNo=111, OutboundAirline='JB', OutboundFlightNo=111,
--             OutboundDate='2011-01-10', ReturnAirline='JB', ReturnFlightNo=111,
--             ReturnDate='2011-01-17', PassengerId=1, PassengerAcct=111,
--             OutboundSeatNo='15C', ReturnSeatNo='16D', Class='Economy',
--             Meal='Vegetarian', TotalFare=450.00, BookingFee=45.00

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 666;
DELETE FROM Includes WHERE ResrNo = 666;
DELETE FROM Reservation WHERE ResrNo = 666;

START TRANSACTION;

-- Check length of stay requirements
SELECT F.MinLengthOfStay, F.MaxLengthOfStay
FROM Flight F
WHERE F.AirlineID = 'JB' AND F.FlightNo = 111;

-- Stay length: DATEDIFF('2011-01-17', '2011-01-10') = 7 days
-- This meets the 0-30 day requirement

-- Insert round-trip reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (666, NOW(), 45.00, 450.00, NULL, 111);

-- Include outbound legs
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 666, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-10'
FROM Leg L
WHERE L.AirlineID = 'JB' AND L.FlightNo = 111
ORDER BY L.LegNo;

-- Include return legs
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 666, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-17'
FROM Leg L
WHERE L.AirlineID = 'JB' AND L.FlightNo = 111
ORDER BY L.LegNo;

-- Add Jane Smith as passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (666, 1, 111, '15C', 'Economy', 'Vegetarian');

COMMIT;

-- VERIFICATION:
SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    R.BookingFee,
    P.FirstName,
    P.LastName,
    RP.Class,
    COUNT(DISTINCT I.Date) AS NumberOfTravelDates,
    COUNT(I.LegNo) AS TotalLegs,
    MIN(I.Date) AS OutboundDate,
    MAX(I.Date) AS ReturnDate,
    DATEDIFF(MAX(I.Date), MIN(I.Date)) AS StayLength,
    'Round-Trip' AS ReservationType
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE R.ResrNo = 666
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee,
         P.FirstName, P.LastName, RP.Class;

-- Expected Output:
-- +--------+---------------------+-----------+------------+-----------+----------+---------+---------------------+-----------+--------------+------------+------------+-----------------+
-- | ResrNo | BookedOn            | TotalFare | BookingFee | FirstName | LastName | Class   | NumberOfTravelDates | TotalLegs | OutboundDate | ReturnDate | StayLength | ReservationType |
-- +--------+---------------------+-----------+------------+-----------+----------+---------+---------------------+-----------+--------------+------------+------------+-----------------+
-- |    666 | 2025-11-03 16:00:00 |    450.00 |      45.00 | Jane      | Smith    | Economy |                   2 |         4 | 2011-01-10   | 2011-01-17 |          7 | Round-Trip      |
-- +--------+---------------------+-----------+------------+-----------+----------+---------+---------------------+-----------+--------------+------------+------------+-----------------+

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 666;
DELETE FROM Includes WHERE ResrNo = 666;
DELETE FROM Reservation WHERE ResrNo = 666;

-- NOTES:
-- Round-trip reservations must satisfy length-of-stay restrictions.
-- Round-trip fares are typically discounted vs. two one-way tickets.
-- System should validate return date is after outbound date.
-- Should check MinLengthOfStay and MaxLengthOfStay from Flight table.

-- ============================================================================
-- TRANSACTION 3.3.2d: Make a Reservation (Multi-City)
-- ============================================================================

-- DEFINITION:
-- Customer creates a multi-city flight reservation visiting multiple destinations

-- INPUT PARAMETERS:
--   @ResrNo        INTEGER       - Unique reservation number
--   @AccountNo     INTEGER       - Customer account number
--   @PassengerId   INTEGER       - Passenger person ID
--   @PassengerAcct INTEGER       - Passenger account number
--   @TotalFare     DECIMAL(10,2) - Total multi-city fare
--   @BookingFee    DECIMAL(10,2) - Booking fee (10% of fare)
--   
--   For each flight segment:
--   @AirlineID_N   CHAR(2)       - Airline code for segment N
--   @FlightNo_N    INTEGER       - Flight number for segment N
--   @Date_N        DATE          - Travel date for segment N
--   @SeatNo_N      CHAR(5)       - Seat assignment for segment N
--   @Class_N       VARCHAR(20)   - Cabin class for segment N
--   @Meal_N        VARCHAR(50)   - Meal preference for segment N

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

-- Insert reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (?, NOW(), ?, ?, NULL, ?);

-- For each flight segment, include all legs
-- Segment 1
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Segment 2
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

-- Segment 3
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;
-- (Repeat for additional segments)

-- Add passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (?, ?, ?, ?, ?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Scenario: Rick Astley plans a world tour with 3 flight segments
--   Segment 1: AA 111 - New York->Los Angeles->Tokyo (Jan 5)
--   Segment 2: JB 111 - San Francisco->Boston->London (Jan 12)
--   Segment 3: AM 1337 - New York->Madagascar (Jan 15)
-- Parameters: ResrNo=777, AccountNo=333, PassengerId=3, PassengerAcct=333,
--             TotalFare=4500.00, BookingFee=450.00

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 777;
DELETE FROM Includes WHERE ResrNo = 777;
DELETE FROM Reservation WHERE ResrNo = 777;

START TRANSACTION;

-- Insert multi-city reservation
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (777, NOW(), 450.00, 4500.00, NULL, 333);

-- Segment 1: American Airlines 111 on Jan 5
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 777, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-05'
FROM Leg L
WHERE L.AirlineID = 'AA' AND L.FlightNo = 111
ORDER BY L.LegNo;

-- Segment 2: JetBlue 111 on Jan 12
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 777, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-12'
FROM Leg L
WHERE L.AirlineID = 'JB' AND L.FlightNo = 111
ORDER BY L.LegNo;

-- Segment 3: Air Madagascar 1337 on Jan 15
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 777, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-15'
FROM Leg L
WHERE L.AirlineID = 'AM' AND L.FlightNo = 1337
ORDER BY L.LegNo;

-- Add Rick Astley as passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (777, 3, 333, '1A', 'First', 'Sushi');

COMMIT;

-- VERIFICATION:
SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    R.BookingFee,
    P.FirstName,
    P.LastName,
    COUNT(DISTINCT CONCAT(I.AirlineID, I.FlightNo)) AS NumberOfFlights,
    COUNT(DISTINCT I.Date) AS TravelDates,
    COUNT(I.LegNo) AS TotalLegs,
    MIN(I.Date) AS FirstDeparture,
    MAX(I.Date) AS LastDeparture,
    'Multi-City' AS ReservationType
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE R.ResrNo = 777
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, R.BookingFee,
         P.FirstName, P.LastName;

-- Expected Output:
-- +--------+---------------------+-----------+------------+-----------+----------+-----------------+-------------+-----------+----------------+---------------+-----------------+
-- | ResrNo | BookedOn            | TotalFare | BookingFee | FirstName | LastName | NumberOfFlights | TravelDates | TotalLegs | FirstDeparture | LastDeparture | ReservationType |
-- +--------+---------------------+-----------+------------+-----------+----------+-----------------+-------------+-----------+----------------+---------------+-----------------+
-- |    777 | 2025-11-03 16:30:00 |   4500.00 |     450.00 | Rick      | Astley   |               3 |           3 |         5 | 2011-01-05     | 2011-01-15    | Multi-City      |
-- +--------+---------------------+-----------+------------+-----------+----------+-----------------+-------------+-----------+----------------+---------------+-----------------+

-- Detailed itinerary:
SELECT 
    I.Date AS TravelDate,
    I.AirlineID,
    A.Name AS AirlineName,
    I.FlightNo,
    GROUP_CONCAT(CONCAT(AP1.City, '->', AP2.City) ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    COUNT(L.LegNo) AS Legs
FROM Includes I
JOIN Airline A ON I.AirlineID = A.Id
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport AP1 ON L.DepAirportID = AP1.Id
JOIN Airport AP2 ON L.ArrAirportID = AP2.Id
WHERE I.ResrNo = 777
GROUP BY I.Date, I.AirlineID, A.Name, I.FlightNo
ORDER BY I.Date;

-- Expected Output:
-- +------------+-----------+-------------------+----------+-----------------------------------------------+------+
-- | TravelDate | AirlineID | AirlineName       | FlightNo | Route                                         | Legs |
-- +------------+-----------+-------------------+----------+-----------------------------------------------+------+
-- | 2011-01-05 | AA        | American Airlines |      111 | New York->Los Angeles, Los Angeles->Tokyo     |    2 |
-- | 2011-01-12 | JB        | JetBlue Airways   |      111 | San Francisco->Boston, Boston->London         |    2 |
-- | 2011-01-15 | AM        | Air Madagascar    |     1337 | New York->Antananarivo                        |    1 |
-- +------------+-----------+-------------------+----------+-----------------------------------------------+------+

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 777;
DELETE FROM Includes WHERE ResrNo = 777;
DELETE FROM Reservation WHERE ResrNo = 777;

-- NOTES:
-- Multi-city allows visiting multiple destinations in one reservation.
-- Each segment can be on different airlines with different dates.
-- No return to origin required (unlike round-trip).
-- Fare is sum of individual segment fares.
-- Ideal for complex itineraries like business trips or world tours.
-- System should validate travel dates are in logical chronological order.

-- ============================================================================
-- TRANSACTION 3.3.2e: Make a Reservation with Flexible Date/Time Search
-- ============================================================================

-- DEFINITION:
-- Customer searches for flights with flexible dates (±N days) and then books
-- This demonstrates the flexible date/time capability required in Section 3.3

-- INPUT PARAMETERS:
--   For Search:
--   @DepCity       VARCHAR(50)  - Departure city
--   @ArrCity       VARCHAR(50)  - Arrival city
--   @PreferredDate DATE         - Preferred travel date
--   @FlexDays      INTEGER      - Flexibility in days (e.g., ±3 days)
--   
--   For Booking (after customer selects from search results):
--   @ResrNo        INTEGER       - Unique reservation number
--   @AccountNo     INTEGER       - Customer account number
--   @SelectedAirline CHAR(2)     - Airline from search results
--   @SelectedFlight  INTEGER     - Flight number from search results
--   @SelectedDate    DATE        - Actual travel date selected
--   (plus other standard booking parameters)

-- SQL STATEMENT (PARAMETERIZED):
/*
-- STEP 1: Flexible Date Search
SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    DATE(L.DepTime) AS FlightDate,
    MIN(L.DepTime) AS DepartureTime,
    MAX(L.ArrTime) AS ArrivalTime,
    TIMESTAMPDIFF(HOUR, MIN(L.DepTime), MAX(L.ArrTime)) AS TotalHours,
    F.NoOfSeats AS TotalSeats,
    (F.NoOfSeats - IFNULL(Booked.Seats, 0)) AS AvailableSeats,
    MIN(FA.FareAmount) AS StartingFare,
    COUNT(L.LegNo) AS NumberOfLegs,
    GROUP_CONCAT(CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
LEFT JOIN Fare FA ON F.AirlineID = FA.AirlineID 
                 AND F.FlightNo = FA.FlightNo 
                 AND FA.FareType = 'OneWay'
LEFT JOIN (
    SELECT I.AirlineID, I.FlightNo, I.Date, 
           COUNT(DISTINCT RP.Id, RP.AccountNo) AS Seats
    FROM Includes I
    JOIN ReservationPassenger RP ON RP.ResrNo = I.ResrNo
    GROUP BY I.AirlineID, I.FlightNo, I.Date
) Booked ON Booked.AirlineID = F.AirlineID 
        AND Booked.FlightNo = F.FlightNo
WHERE APDep.City = ?
  AND APArr.City = ?
  AND DATE(L.DepTime) BETWEEN DATE_SUB(?, INTERVAL ? DAY) 
                          AND DATE_ADD(?, INTERVAL ? DAY)
  AND (F.NoOfSeats - IFNULL(Booked.Seats, 0)) > 0
GROUP BY F.AirlineID, A.Name, F.FlightNo, DATE(L.DepTime), F.NoOfSeats, Booked.Seats
ORDER BY FlightDate, MIN(L.DepTime), MIN(FA.FareAmount);

-- STEP 2: Book Selected Flight (standard one-way booking)
START TRANSACTION;

INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (?, NOW(), ?, ?, NULL, ?);

INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT ?, L.AirlineID, L.FlightNo, L.LegNo, ?
FROM Leg L
WHERE L.AirlineID = ? AND L.FlightNo = ?
ORDER BY L.LegNo;

INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (?, ?, ?, ?, ?, ?);

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Scenario: Jane Smith wants to fly from San Francisco to London
--           around January 10, 2011 (flexible ±2 days)
-- Search Parameters: DepCity='San Francisco', ArrCity='London',
--                   PreferredDate='2011-01-10', FlexDays=2

-- STEP 1: FLEXIBLE DATE SEARCH
SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    DATE(L.DepTime) AS FlightDate,
    MIN(L.DepTime) AS DepartureTime,
    MAX(L.ArrTime) AS ArrivalTime,
    TIMESTAMPDIFF(HOUR, MIN(L.DepTime), MAX(L.ArrTime)) AS TotalHours,
    F.NoOfSeats AS TotalSeats,
    MIN(FA.FareAmount) AS StartingFare,
    COUNT(L.LegNo) AS NumberOfLegs,
    GROUP_CONCAT(CONCAT(L.DepAirportID, '->', L.ArrAirportID) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
LEFT JOIN Fare FA ON F.AirlineID = FA.AirlineID 
                 AND F.FlightNo = FA.FlightNo 
                 AND FA.FareType = 'OneWay'
WHERE APDep.City = 'San Francisco'
  AND APArr.City = 'London'
  AND DATE(L.DepTime) BETWEEN DATE_SUB('2011-01-10', INTERVAL 2 DAY) 
                          AND DATE_ADD('2011-01-10', INTERVAL 2 DAY)
GROUP BY F.AirlineID, A.Name, F.FlightNo, DATE(L.DepTime), F.NoOfSeats
ORDER BY DATE(L.DepTime), MIN(L.DepTime), MIN(FA.FareAmount);

-- Expected Search Output:
-- +-----------+-----------------+----------+------------+---------------------+---------------------+------------+------------+--------------+--------------+----------------------+
-- | AirlineID | AirlineName     | FlightNo | FlightDate | DepartureTime       | ArrivalTime         | TotalHours | TotalSeats | StartingFare | NumberOfLegs | Route                |
-- +-----------+-----------------+----------+------------+---------------------+---------------------+------------+------------+--------------+--------------+----------------------+
-- | JB        | JetBlue Airways |      111 | 2011-01-10 | 2011-01-10 14:00:00 | 2011-01-11 05:00:00 |         15 |        150 |       250.00 |            2 | SFO->BOS, BOS->LHR   |
-- +-----------+-----------------+----------+------------+---------------------+---------------------+------------+------------+--------------+--------------+----------------------+

-- STEP 2: Customer selects JetBlue 111 on Jan 10 and books it
-- Booking Parameters: ResrNo=888, AccountNo=111, SelectedAirline='JB',
--                    SelectedFlight=111, SelectedDate='2011-01-10',
--                    PassengerId=1, PassengerAcct=111, SeatNo='20A',
--                    Class='Economy', Meal='Vegetarian',
--                    TotalFare=250.00, BookingFee=25.00

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 888;
DELETE FROM Includes WHERE ResrNo = 888;
DELETE FROM Reservation WHERE ResrNo = 888;

START TRANSACTION;

INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (888, NOW(), 25.00, 250.00, NULL, 111);

INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 888, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-10'
FROM Leg L
WHERE L.AirlineID = 'JB' AND L.FlightNo = 111
ORDER BY L.LegNo;

INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (888, 1, 111, '20A', 'Economy', 'Vegetarian');

COMMIT;

-- VERIFICATION:
SELECT 
    R.ResrNo,
    P.FirstName,
    P.LastName,
    R.TotalFare,
    I.AirlineID,
    I.FlightNo,
    I.Date AS TravelDate,
    RP.SeatNo,
    RP.Class,
    'Flexible Date Booking' AS BookingType
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE R.ResrNo = 888
LIMIT 1;

-- Expected Output:
-- +--------+-----------+----------+-----------+-----------+----------+------------+--------+---------+------------------------+
-- | ResrNo | FirstName | LastName | TotalFare | AirlineID | FlightNo | TravelDate | SeatNo | Class   | BookingType            |
-- +--------+-----------+----------+-----------+-----------+----------+------------+--------+---------+------------------------+
-- |    888 | Jane      | Smith    |    250.00 | JB        |      111 | 2011-01-10 | 20A    | Economy | Flexible Date Booking  |
-- +--------+-----------+----------+-----------+-----------+----------+------------+--------+---------+------------------------+

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 888;
DELETE FROM Includes WHERE ResrNo = 888;
DELETE FROM Reservation WHERE ResrNo = 888;

-- NOTES:
-- Flexible date/time search allows customers to see options across date range.
-- Shows all available flights within ±FlexDays of preferred date.
-- Results sorted by date and price to help customer find best option.
-- Customer can compare prices across different dates.
-- Similar flexibility can be applied to departure time (e.g., ±4 hours).
-- This is a common feature on sites like Google Flights, Kayak, Expedia.
-- After seeing flexible options, customer books using standard reservation process.


-- ============================================================================
-- TRANSACTION 3.3.3: Cancel a Reservation
-- ============================================================================

-- DEFINITION:
-- Customer cancels an existing reservation online

-- INPUT PARAMETERS:
--   @ResrNo    INTEGER - Reservation number to cancel
--   @AccountNo INTEGER - Customer account (for verification)

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

-- Verify ownership before deleting
DELETE FROM ReservationPassenger 
WHERE ResrNo = ? 
  AND ResrNo IN (SELECT ResrNo FROM Reservation WHERE AccountNo = ?);

DELETE FROM Includes 
WHERE ResrNo = ? 
  AND ResrNo IN (SELECT ResrNo FROM Reservation WHERE AccountNo = ?);

DELETE FROM Reservation 
WHERE ResrNo = ? AND AccountNo = ?;

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: ResrNo=555, AccountNo=111

-- First create the reservation to cancel
DELETE FROM ReservationPassenger WHERE ResrNo = 555;
DELETE FROM Includes WHERE ResrNo = 555;
DELETE FROM Reservation WHERE ResrNo = 555;

INSERT INTO Reservation VALUES (555, NOW(), 330.00, 3300.00, NULL, 111);
INSERT INTO Includes VALUES (555, 'AM', 1337, 1, '2011-01-13');
INSERT INTO ReservationPassenger VALUES (555, 1, 111, '1A', 'First', 'Vegetarian');

-- Now cancel it (Transaction 3.3.3 execution)
START TRANSACTION;

DELETE FROM ReservationPassenger 
WHERE ResrNo = 555 
  AND ResrNo IN (SELECT ResrNo FROM Reservation WHERE AccountNo = 111);

DELETE FROM Includes 
WHERE ResrNo = 555 
  AND ResrNo IN (SELECT ResrNo FROM Reservation WHERE AccountNo = 111);

DELETE FROM Reservation 
WHERE ResrNo = 555 AND AccountNo = 111;

COMMIT;

-- VERIFICATION (should return 0):
SELECT COUNT(*) AS ReservationExists FROM Reservation WHERE ResrNo = 555;

-- OUTPUT:
/*
Expected: 0 (reservation successfully canceled)
*/

-- NOTES:
-- Verification ensures customer can only cancel their own reservations.
-- Transaction ensures all related records deleted atomically.
-- In production, implement refund policy logic.

-- ============================================================================
-- TRANSACTION 3.3.4: View Customer's Current Reservations
-- ============================================================================

-- DEFINITION:
-- Display all upcoming (future) reservations for a customer

-- INPUT PARAMETERS:
--   @AccountNo INTEGER - Customer account number

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    MIN(L.DepTime) AS DepartureDate,
    MAX(L.ArrTime) AS ReturnDate,
    GROUP_CONCAT(CONCAT(APDep.City, '->', APArr.City) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    COUNT(DISTINCT I.LegNo) AS TotalLegs,
    RP.SeatNo,
    RP.Class
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
WHERE R.AccountNo = ?
  AND MIN(L.DepTime) >= NOW()
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, RP.SeatNo, RP.Class
ORDER BY MIN(L.DepTime);
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo=222
-- Note: Demo data is in 2011, so showing all reservations for demonstration

SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    MIN(L.DepTime) AS DepartureDate,
    MAX(L.ArrTime) AS ReturnDate,
    GROUP_CONCAT(CONCAT(APDep.City, '->', APArr.City) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    COUNT(DISTINCT I.LegNo) AS TotalLegs,
    RP.SeatNo,
    RP.Class
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
WHERE R.AccountNo = 222
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, RP.SeatNo, RP.Class
ORDER BY MIN(L.DepTime);

-- OUTPUT:
/*
Expected: Reservation 111, New York->Los Angeles->Tokyo, 2 legs
*/


-- NOTES:
-- Shows only future reservations in production (demo data is historical).
-- Displays complete journey with all legs.
-- Useful for "My Trips" page.

-- ============================================================================
-- TRANSACTION 3.3.5: View Travel Itinerary for a Given Reservation
-- ============================================================================

-- DEFINITION:
-- Display detailed travel itinerary for a specific reservation

-- INPUT PARAMETERS:
--   @ResrNo    INTEGER - Reservation number
--   @AccountNo INTEGER - Customer account (for verification)

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    R.BookingFee,
    I.LegNo,
    L.AirlineID,
    AL.Name AS AirlineName,
    L.FlightNo,
    L.DepAirportID,
    APDep.Name AS DepartureAirport,
    APDep.City AS DepartureCity,
    L.DepTime,
    L.ArrAirportID,
    APArr.Name AS ArrivalAirport,
    APArr.City AS ArrivalCity,
    L.ArrTime,
    TIMESTAMPDIFF(MINUTE, L.DepTime, L.ArrTime) AS FlightDuration,
    RP.SeatNo,
    RP.Class,
    RP.Meal,
    P.FirstName AS PassengerFirstName,
    P.LastName AS PassengerLastName
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airline AL ON L.AirlineID = AL.Id
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
WHERE R.ResrNo = ? AND R.AccountNo = ?
ORDER BY I.LegNo;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: ResrNo=111, AccountNo=222

SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    R.BookingFee,
    I.LegNo,
    L.AirlineID,
    AL.Name AS AirlineName,
    L.FlightNo,
    L.DepAirportID,
    APDep.Name AS DepartureAirport,
    APDep.City AS DepartureCity,
    L.DepTime,
    L.ArrAirportID,
    APArr.Name AS ArrivalAirport,
    APArr.City AS ArrivalCity,
    L.ArrTime,
    TIMESTAMPDIFF(MINUTE, L.DepTime, L.ArrTime) AS FlightDuration,
    RP.SeatNo,
    RP.Class,
    RP.Meal,
    P.FirstName AS PassengerFirstName,
    P.LastName AS PassengerLastName
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airline AL ON L.AirlineID = AL.Id
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
WHERE R.ResrNo = 111 AND R.AccountNo = 222
ORDER BY I.LegNo;

-- OUTPUT:
/*
Expected: 2 legs - LGA->LAX (360 min), LAX->HND (750 min), John Doe
*/


-- NOTES:
-- Complete itinerary with all flight details.
-- Shows layover time between legs.
-- Can be formatted as printable boarding pass.
-- Verification ensures customer only sees their own reservations.

-- ============================================================================
-- TRANSACTION 3.3.6: View Customer's Current Bid on a Reverse Auction
-- ============================================================================

-- DEFINITION:
-- Display customer's current bid status for a specific flight auction

-- INPUT PARAMETERS:
--   @AccountNo INTEGER - Customer account number
--   @AirlineID CHAR(2) - Airline code
--   @FlightNo  INTEGER - Flight number
--   @LegNo     INTEGER - Leg number

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    AU.AccountNo,
    AU.AirlineID,
    AL.Name AS AirlineName,
    AU.FlightNo,
    AU.LegNo,
    L.DepAirportID,
    APDep.City AS DepartureCity,
    L.ArrAirportID,
    APArr.City AS ArrivalCity,
    L.DepTime AS FlightDate,
    AU.Class,
    AU.NYOP AS BidAmount,
    AU.Date AS BidDate,
    AU.Accepted AS BidAccepted,
    CASE 
        WHEN AU.Accepted = TRUE THEN 'Accepted - Reservation Created'
        ELSE 'Pending Review'
    END AS BidStatus
FROM Auctions AU
JOIN Airline AL ON AU.AirlineID = AL.Id
JOIN Leg L ON AU.AirlineID = L.AirlineID 
          AND AU.FlightNo = L.FlightNo 
          AND AU.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE AU.AccountNo = ?
  AND AU.AirlineID = ?
  AND AU.FlightNo = ?
  AND AU.LegNo = ?
ORDER BY AU.Date DESC
LIMIT 1;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo=222, AirlineID='AA', FlightNo=111, LegNo=1

SELECT 
    AU.AccountNo,
    AU.AirlineID,
    AL.Name AS AirlineName,
    AU.FlightNo,
    AU.LegNo,
    L.DepAirportID,
    APDep.City AS DepartureCity,
    L.ArrAirportID,
    APArr.City AS ArrivalCity,
    L.DepTime AS FlightDate,
    AU.Class,
    AU.NYOP AS BidAmount,
    AU.Date AS BidDate,
    AU.Accepted AS BidAccepted,
    CASE 
        WHEN AU.Accepted = TRUE THEN 'Accepted - Reservation Created'
        ELSE 'Pending Review'
    END AS BidStatus
FROM Auctions AU
JOIN Airline AL ON AU.AirlineID = AL.Id
JOIN Leg L ON AU.AirlineID = L.AirlineID 
          AND AU.FlightNo = L.FlightNo 
          AND AU.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE AU.AccountNo = 222
  AND AU.AirlineID = 'AA'
  AND AU.FlightNo = 111
  AND AU.LegNo = 1
ORDER BY AU.Date DESC
LIMIT 1;

-- OUTPUT:
/*
Expected: John Doe's bid of $400 on AA 111, Status: Accepted
*/


-- NOTES:
-- Shows customer's most recent bid for the flight.
-- Customer can see if they need to bid higher.
-- Hidden fare not shown to customer (only system knows).

-- ============================================================================
-- TRANSACTION 3.3.7: View Bid History for a Reverse Auction
-- ============================================================================

-- DEFINITION:
-- Display all bids for a specific flight auction (anonymized)

-- INPUT PARAMETERS:
--   @AirlineID CHAR(2)     - Airline code
--   @FlightNo  INTEGER     - Flight number
--   @LegNo     INTEGER     - Leg number
--   @Class     VARCHAR(20) - Cabin class

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    AU.Date AS BidDate,
    AU.NYOP AS BidAmount,
    AU.Accepted AS BidAccepted,
    AU.Class,
    COUNT(*) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS TotalBids,
    AVG(AU.NYOP) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS AvgBidAmount,
    MIN(AU.NYOP) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS MinBid,
    MAX(AU.NYOP) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS MaxBid
FROM Auctions AU
WHERE AU.AirlineID = ?
  AND AU.FlightNo = ?
  AND AU.LegNo = ?
  AND AU.Class = ?
ORDER BY AU.Date DESC;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AirlineID='AA', FlightNo=111, LegNo=1, Class='Economy'

SELECT 
    AU.Date AS BidDate,
    AU.NYOP AS BidAmount,
    AU.Accepted AS BidAccepted,
    AU.Class,
    COUNT(*) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS TotalBids,
    AVG(AU.NYOP) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS AvgBidAmount,
    MIN(AU.NYOP) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS MinBid,
    MAX(AU.NYOP) OVER (PARTITION BY AU.AirlineID, AU.FlightNo, AU.LegNo, AU.Class) AS MaxBid
FROM Auctions AU
WHERE AU.AirlineID = 'AA'
  AND AU.FlightNo = 111
  AND AU.LegNo = 1
  AND AU.Class = 'Economy'
ORDER BY AU.Date DESC;

-- OUTPUT:
/*
Expected: 1 bid of $400, accepted, avg=$400, min=$400, max=$400
*/


-- NOTES:
-- Shows all bids for transparency (customer names hidden for privacy).
-- Window functions provide statistics without grouping.
-- Helps customers gauge competitive pricing.

-- ============================================================================
-- TRANSACTION 3.3.8: Place a Bid in Reverse Auction
-- ============================================================================

-- DEFINITION:
-- Customer submits a "Name Your Own Price" bid for a flight seat

-- INPUT PARAMETERS:
--   @AccountNo INTEGER      - Customer account number
--   @AirlineID CHAR(2)      - Airline code
--   @FlightNo  INTEGER      - Flight number
--   @LegNo     INTEGER      - Leg number
--   @Class     VARCHAR(20)  - Cabin class
--   @NYOP      DECIMAL(10,2)- Bid amount

-- SQL STATEMENT (PARAMETERIZED):
/*
START TRANSACTION;

-- Insert bid (system determines acceptance based on hidden fare)
INSERT INTO Auctions (AccountNo, AirlineID, FlightNo, LegNo, Class, Date, NYOP, Accepted)
SELECT ?, ?, ?, ?, ?, NOW(), ?,
       CASE 
           WHEN ? >= (SELECT FareAmount FROM Fare 
                      WHERE AirlineID = ? AND FlightNo = ? 
                        AND FareType = 'Hidden' AND Class = ? LIMIT 1)
           THEN TRUE
           ELSE FALSE
       END;

COMMIT;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo=111, AirlineID='JB', FlightNo=111, LegNo=1,
--             Class='Economy', NYOP=250.00

-- CLEANUP FIRST
DELETE FROM Auctions 
WHERE AccountNo = 111 
  AND AirlineID = 'JB' 
  AND FlightNo = 111 
  AND LegNo = 1;

START TRANSACTION;

-- Place bid (auto-evaluated against hidden fare)
INSERT INTO Auctions (AccountNo, AirlineID, FlightNo, LegNo, Class, Date, NYOP, Accepted)
SELECT 111, 'JB', 111, 1, 'Economy', NOW(), 250.00,
       CASE 
           WHEN 250.00 >= (SELECT FareAmount FROM Fare 
                           WHERE AirlineID = 'JB' AND FlightNo = 111 
                             AND FareType = 'Hidden' AND Class = 'Economy' LIMIT 1)
           THEN TRUE
           ELSE FALSE
       END;

COMMIT;

-- VERIFICATION:
SELECT 
    AU.AccountNo,
    P.FirstName,
    P.LastName,
    AU.NYOP AS BidAmount,
    AU.Accepted,
    CASE 
        WHEN AU.Accepted = TRUE THEN 'Congratulations! Your bid was accepted.'
        ELSE 'Sorry, bid too low. Please try again with a higher amount.'
    END AS Result
FROM Auctions AU
JOIN Customer C ON AU.AccountNo = C.AccountNo
JOIN Person P ON C.Id = P.Id
WHERE AU.AccountNo = 111
  AND AU.AirlineID = 'JB'
  AND AU.FlightNo = 111
  AND AU.LegNo = 1
ORDER BY AU.Date DESC
LIMIT 1;

-- OUTPUT:
/*
Expected: Jane Smith, $250 bid, Accepted (hidden fare is $200)
*/

-- CLEANUP AFTER
DELETE FROM Auctions 
WHERE AccountNo = 111 
  AND AirlineID = 'JB' 
  AND FlightNo = 111 
  AND LegNo = 1;

-- NOTES:
-- Bid automatically compared to hidden fare (minimum airline will accept).
-- Customer sees only acceptance status, not the hidden fare amount.
-- Can bid multiple times with increasing amounts if rejected.
-- If accepted, system should automatically create reservation.

-- ============================================================================
-- TRANSACTION 3.3.9: View Reservation History (All Past and Current)
-- ============================================================================

-- DEFINITION:
-- Display complete reservation history for a customer

-- INPUT PARAMETERS:
--   @AccountNo INTEGER - Customer account number

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    MIN(L.DepTime) AS DepartureDate,
    MAX(L.ArrTime) AS ArrivalDate,
    COUNT(DISTINCT I.LegNo) AS TotalLegs,
    GROUP_CONCAT(CONCAT(APDep.City, '->', APArr.City) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    CASE 
        WHEN MIN(L.DepTime) > NOW() THEN 'Upcoming'
        WHEN MAX(L.ArrTime) < NOW() THEN 'Completed'
        ELSE 'In Progress'
    END AS TripStatus
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE R.AccountNo = ?
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare
ORDER BY R.ResrDate DESC;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo=222

SELECT 
    R.ResrNo,
    R.ResrDate AS BookedOn,
    R.TotalFare,
    MIN(L.DepTime) AS DepartureDate,
    MAX(L.ArrTime) AS ArrivalDate,
    COUNT(DISTINCT I.LegNo) AS TotalLegs,
    GROUP_CONCAT(CONCAT(APDep.City, '->', APArr.City) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS Route,
    CASE 
        WHEN MIN(L.DepTime) > NOW() THEN 'Upcoming'
        WHEN MAX(L.ArrTime) < NOW() THEN 'Completed'
        ELSE 'In Progress'
    END AS TripStatus
FROM Reservation R
JOIN Includes I ON R.ResrNo = I.ResrNo
JOIN Leg L ON I.AirlineID = L.AirlineID 
          AND I.FlightNo = L.FlightNo 
          AND I.LegNo = L.LegNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
WHERE R.AccountNo = 222
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare
ORDER BY R.ResrDate DESC;

-- OUTPUT:
/*
Expected: Reservation 111, New York->Los Angeles->Tokyo, Completed
*/


-- NOTES:
-- Shows complete travel history with status indicators.
-- Useful for tracking past trips and managing upcoming travel.
-- Status helps identify active vs. completed reservations.

-- ============================================================================
-- TRANSACTION 3.3.10: View Best-Seller List of Flights
-- ============================================================================

-- DEFINITION:
-- Display most popular flights by number of reservations

-- INPUT PARAMETERS:
--   @Limit INTEGER - Number of top flights to show (optional, default 10)

-- SQL STATEMENT (PARAMETERIZED):
/*
SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    GROUP_CONCAT(CONCAT(APDep.City, '->', APArr.City) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS PopularRoute,
    COUNT(DISTINCT R.ResrNo) AS TotalBookings,
    AVG(R.TotalFare) AS AverageFare,
    MIN(FA.FareAmount) AS StartingPrice,
    F.NoOfSeats,
    ROUND(COUNT(DISTINCT RP.Id) * 100.0 / F.NoOfSeats, 2) AS PopularityScore
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
LEFT JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
LEFT JOIN Airport APDep ON L.DepAirportID = APDep.Id
LEFT JOIN Airport APArr ON L.ArrAirportID = APArr.Id
LEFT JOIN Includes I ON F.AirlineID = I.AirlineID AND F.FlightNo = I.FlightNo
LEFT JOIN Reservation R ON I.ResrNo = R.ResrNo
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
LEFT JOIN Fare FA ON F.AirlineID = FA.AirlineID 
                 AND F.FlightNo = FA.FlightNo 
                 AND FA.FareType = 'OneWay'
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats
HAVING TotalBookings > 0
ORDER BY TotalBookings DESC, PopularityScore DESC
LIMIT ?;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: Limit=10

SELECT 
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    GROUP_CONCAT(CONCAT(APDep.City, '->', APArr.City) 
                 ORDER BY L.LegNo SEPARATOR ', ') AS PopularRoute,
    COUNT(DISTINCT R.ResrNo) AS TotalBookings,
    AVG(R.TotalFare) AS AverageFare,
    MIN(FA.FareAmount) AS StartingPrice,
    F.NoOfSeats,
    ROUND(COUNT(DISTINCT RP.Id) * 100.0 / F.NoOfSeats, 2) AS PopularityScore
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
LEFT JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
LEFT JOIN Airport APDep ON L.DepAirportID = APDep.Id
LEFT JOIN Airport APArr ON L.ArrAirportID = APArr.Id
LEFT JOIN Includes I ON F.AirlineID = I.AirlineID AND F.FlightNo = I.FlightNo
LEFT JOIN Reservation R ON I.ResrNo = R.ResrNo
LEFT JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
LEFT JOIN Fare FA ON F.AirlineID = FA.AirlineID 
                 AND F.FlightNo = FA.FlightNo 
                 AND FA.FareType = 'OneWay'
GROUP BY F.AirlineID, A.Name, F.FlightNo, F.NoOfSeats
HAVING TotalBookings > 0
ORDER BY TotalBookings DESC, PopularityScore DESC
LIMIT 10;

-- OUTPUT:
/*
Expected: All 3 flights with 1 booking each, sorted by fare
*/


-- NOTES:
-- Helps customers discover popular destinations and routes.
-- All demo flights have 1 booking each.
-- In production with more data, would show truly trending flights.
-- PopularityScore indicates demand relative to capacity.

-- ============================================================================
-- TRANSACTION 3.3.11: View Personalized Flight Suggestion List
-- ============================================================================

-- DEFINITION:
-- Recommend flights based on customer's travel history and preferences

-- INPUT PARAMETERS:
--   @AccountNo INTEGER - Customer account number

-- SQL STATEMENT (PARAMETERIZED):
/*
WITH CustomerRoutes AS (
    SELECT L.DepAirportID, L.ArrAirportID, COUNT(*) AS TimesFlown
    FROM Reservation R
    JOIN Includes I ON R.ResrNo = I.ResrNo
    JOIN Leg L ON I.AirlineID = L.AirlineID 
              AND I.FlightNo = L.FlightNo 
              AND I.LegNo = L.LegNo
    WHERE R.AccountNo = ?
    GROUP BY L.DepAirportID, L.ArrAirportID
)
SELECT DISTINCT
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    APDep.City AS DepartureCity,
    APArr.City AS DestinationCity,
    MIN(FA.FareAmount) AS BestFare,
    CR.TimesFlown AS PreviousTrips,
    CASE 
        WHEN CR.TimesFlown > 0 THEN 'You flew this route before!'
        ELSE 'New destination for you'
    END AS Recommendation
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
LEFT JOIN CustomerRoutes CR ON L.DepAirportID = CR.DepAirportID 
                            AND L.ArrAirportID = CR.ArrAirportID
JOIN Fare FA ON F.AirlineID = FA.AirlineID 
             AND F.FlightNo = FA.FlightNo 
             AND FA.FareType = 'OneWay'
GROUP BY F.AirlineID, A.Name, F.FlightNo, APDep.City, APArr.City, CR.TimesFlown
ORDER BY CR.TimesFlown DESC, MIN(FA.FareAmount)
LIMIT 10;
*/

-- EXECUTION WITH DEMO DATA:
-- Parameters: AccountNo = 222 (John Doe)

WITH CustomerRoutes AS (
    SELECT L.DepAirportID, L.ArrAirportID, COUNT(*) AS TimesFlown
    FROM Reservation R
    JOIN Includes I ON R.ResrNo = I.ResrNo
    JOIN Leg L ON I.AirlineID = L.AirlineID 
              AND I.FlightNo = L.FlightNo 
              AND I.LegNo = L.LegNo
    WHERE R.AccountNo = 222
    GROUP BY L.DepAirportID, L.ArrAirportID
)
SELECT DISTINCT
    F.AirlineID,
    A.Name AS AirlineName,
    F.FlightNo,
    APDep.City AS DepartureCity,
    APArr.City AS DestinationCity,
    MIN(FA.FareAmount) AS BestFare,
    CR.TimesFlown AS PreviousTrips,
    CASE 
        WHEN CR.TimesFlown > 0 THEN 'You flew this route before!'
        ELSE 'New destination for you'
    END AS Recommendation
FROM Flight F
JOIN Airline A ON F.AirlineID = A.Id
JOIN Leg L ON F.AirlineID = L.AirlineID AND F.FlightNo = L.FlightNo
JOIN Airport APDep ON L.DepAirportID = APDep.Id
JOIN Airport APArr ON L.ArrAirportID = APArr.Id
LEFT JOIN CustomerRoutes CR ON L.DepAirportID = CR.DepAirportID 
                            AND L.ArrAirportID = CR.ArrAirportID
JOIN Fare FA ON F.AirlineID = FA.AirlineID 
             AND F.FlightNo = FA.FlightNo 
             AND FA.FareType = 'OneWay'
GROUP BY F.AirlineID, A.Name, F.FlightNo, APDep.City, APArr.City, CR.TimesFlown
ORDER BY CR.TimesFlown DESC, MIN(FA.FareAmount)
LIMIT 10;

-- OUTPUT:
/*
Expected: LGA->LAX and LAX->HND marked as "You flew this route before!"
*/

-- NOTES:
-- Prioritizes routes customer has traveled before (likely to book again).
-- Shows best available fares for each route.
-- Useful for "Recommended for You" homepage feature.

