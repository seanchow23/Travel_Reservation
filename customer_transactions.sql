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

-- ============================================================================
-- TRANSACTION 3.3.2: Make a Reservation (One-Way)
-- ============================================================================

-- DEFINITION:
-- Customer creates a new one-way flight reservation online

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

-- Insert reservation (RepSSN is NULL for online bookings)
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
-- Parameters: ResrNo=555, AccountNo=111, AirlineID='AM', FlightNo=1337,
--             TravelDate='2011-01-13', PassengerId=1, PassengerAcct=111,
--             SeatNo='1A', Class='First', Meal='Vegetarian', 
--             TotalFare=3300.00, BookingFee=330.00

-- CLEANUP FIRST
DELETE FROM ReservationPassenger WHERE ResrNo = 555;
DELETE FROM Includes WHERE ResrNo = 555;
DELETE FROM Reservation WHERE ResrNo = 555;

START TRANSACTION;

-- Insert reservation (online booking - no RepSSN)
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES (555, NOW(), 330.00, 3300.00, NULL, 111);

-- Include all legs for Air Madagascar Flight 1337
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
SELECT 555, L.AirlineID, L.FlightNo, L.LegNo, '2011-01-13'
FROM Leg L
WHERE L.AirlineID = 'AM' AND L.FlightNo = 1337
ORDER BY L.LegNo;

-- Add Jane Smith as passenger
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES (555, 1, 111, '1A', 'First', 'Vegetarian');

COMMIT;

-- VERIFICATION:
SELECT R.ResrNo, R.ResrDate, R.TotalFare, P.FirstName, P.LastName, 
       RP.SeatNo, RP.Class, COUNT(I.LegNo) AS Legs
FROM Reservation R
JOIN ReservationPassenger RP ON R.ResrNo = RP.ResrNo
JOIN Person P ON RP.Id = P.Id
JOIN Includes I ON R.ResrNo = I.ResrNo
WHERE R.ResrNo = 555
GROUP BY R.ResrNo, R.ResrDate, R.TotalFare, P.FirstName, 
         P.LastName, RP.SeatNo, RP.Class;

-- OUTPUT:
/*
Expected: Jane Smith, Seat 1A, First Class, 1 leg, $3300.00
*/

-- CLEANUP AFTER
DELETE FROM ReservationPassenger WHERE ResrNo = 555;
DELETE FROM Includes WHERE ResrNo = 555;
DELETE FROM Reservation WHERE ResrNo = 555;

-- NOTES:
-- Online reservations have RepSSN = NULL (no customer rep involvement).
-- Transaction ensures atomicity across Reservation, Includes, ReservationPassenger.
-- Booking fee typically 10% of total fare.

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
[PASTE YOUR OUTPUT HERE]
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
[PASTE YOUR OUTPUT HERE]
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
[PASTE YOUR OUTPUT HERE]
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
-- Parameters: AccountNo=222 (John Doe)

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


