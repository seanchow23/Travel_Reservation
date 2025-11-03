
USE project_2;

-- DEMO DATA INSERTION

-- Insert Airlines
INSERT INTO Airline (Id, Name) VALUES
('AB', 'Air Berlin'),
('AJ', 'Air Japan'),
('AM', 'Air Madagascar'),
('AA', 'American Airlines'),
('BA', 'British Airways'),
('DL', 'Delta Airlines'),
('JB', 'JetBlue Airways'),
('LH', 'Lufthansa'),
('SW', 'Southwest Airlines'),
('UA', 'United Airlines');

-- Insert Airports
INSERT INTO Airport (Id, Name, City, Country) VALUES
('TXL', 'Berlin Tegel', 'Berlin', 'Germany'),
('ORD', 'Chicago O''Hare International', 'Chicago', 'Illinois'),
('ATL', 'Hartsfield-Jackson Atlanta Int', 'Atlanta', 'United States of America'),
('TNR', 'Ivato International', 'Antananarivo', 'Madagascar'),
('JFK', 'John F. Kennedy International', 'New York', 'United States of America'),
('LGA', 'LaGuardia', 'New York', 'United States of America'),
('BOS', 'Logan International', 'Boston', 'United States of America'),
('LHR', 'London Heathrow', 'London', 'United Kingdom'),
('LAX', 'Los Angeles International', 'Los Angeles', 'United States of America'),
('SFO', 'San Francisco International', 'San Francisco', 'United States of America'),
('HND', 'Tokyo International', 'Tokyo', 'Japan');

-- Insert Flights (Added MinLengthOfStay and MaxLengthOfStay)
INSERT INTO Flight (AirlineID, FlightNo, NoOfSeats, DaysOperating, MinLengthOfStay, MaxLengthOfStay)
VALUES
('AA', 111, 100, '1010100', 0, 30),
('JB', 111, 150, '1111111', 0, 30),
('AM', 1337, 33, '0000011', 3, 14);

-- Insert Flight Legs
-- American Airlines #111: LGA -> LAX -> HND
INSERT INTO Leg (AirlineID, FlightNo, LegNo, DepAirportID, ArrAirportID, DepTime, ArrTime)
VALUES
('AA', 111, 1, 'LGA', 'LAX', '2011-01-05 11:00:00', '2011-01-05 17:00:00'),
('AA', 111, 2, 'LAX', 'HND', '2011-01-05 19:00:00', '2011-01-06 07:30:00');

-- JetBlue #111: SFO -> BOS -> LHR
INSERT INTO Leg (AirlineID, FlightNo, LegNo, DepAirportID, ArrAirportID, DepTime, ArrTime)
VALUES
('JB', 111, 1, 'SFO', 'BOS', '2011-01-10 14:00:00', '2011-01-10 19:30:00'),
('JB', 111, 2, 'BOS', 'LHR', '2011-01-10 22:30:00', '2011-01-11 05:00:00');

-- Air Madagascar #1337: JFK -> TNR
INSERT INTO Leg (AirlineID, FlightNo, LegNo, DepAirportID, ArrAirportID, DepTime, ArrTime)
VALUES
('AM', 1337, 1, 'JFK', 'TNR', '2011-01-13 07:00:00', '2011-01-14 03:00:00');

-- Insert Fares 
INSERT INTO Fare (AirlineID, FlightNo, FareType, Class, FareAmount)
VALUES
-- American Airlines Flight 111 Fares
('AA', 111, 'OneWay', 'Economy', 400.00),
('AA', 111, 'OneWay', 'Business', 800.00),
('AA', 111, 'OneWay', 'First', 1200.00),
('AA', 111, 'RoundTrip', 'Economy', 750.00),
('AA', 111, 'Hidden', 'Economy', 300.00),  -- Min bid airline will accept

-- JetBlue Flight 111 Fares
('JB', 111, 'OneWay', 'Economy', 250.00),
('JB', 111, 'OneWay', 'First', 500.00),
('JB', 111, 'RoundTrip', 'Economy', 450.00),
('JB', 111, 'Hidden', 'Economy', 200.00),
('JB', 111, 'Hidden', 'First', 400.00),

-- Air Madagascar Flight 1337 Fares
('AM', 1337, 'OneWay', 'First', 3000.00),
('AM', 1337, 'Hidden', 'First', 2500.00);

-- Insert Advance Purchase Discounts 
INSERT INTO AdvPurchaseDiscount (AirlineID, Days, DiscountRate)
VALUES
('AA', 7, 5.00),
('AA', 14, 10.00),
('AA', 21, 15.00),
('JB', 7, 7.00),
('JB', 14, 12.00),
('AM', 14, 10.00);

-- Insert Persons 
INSERT INTO Person (Id, FirstName, LastName, Address, City, State, ZipCode, Phone)
VALUES
-- Customers/Passengers
(1, 'Jane', 'Smith', '100 Nicolls Rd', 'Stony Brook', 'NY', 11790, '555-555-5555'),
(2, 'John', 'Doe', '123 N Fake Street', 'New York', 'NY', 10001, '123-123-1234'),
(3, 'Rick', 'Astley', '1337 Internet Lane', 'Los Angeles', 'CA', 90001, '314-159-2653'),
-- Sample ADDED Employee data
(101, 'Alice', 'Johnson', '50 Union Ave', 'Stony Brook', 'NY', 11790, '631-555-0001'),
(102, 'Bob', 'Williams', '75 Main St', 'Port Jefferson', 'NY', 11777, '631-555-0002'),
(103, 'Carol', 'Manager', '100 Admin Blvd', 'Stony Brook', 'NY', 11790, '631-555-0003');

-- Insert Customers 
INSERT INTO Customer (Id, AccountNo, Email, CreationDate, Rating, CreditCardNo)
VALUES
(1, 111, 'awesomejane@ftw.com', '2011-01-05 00:00:00', 5, '4111111111111111'),
(2, 222, 'jdoe@woot.com', '2011-01-05 00:00:00', 7, '4222222222222222'),
(3, 333, 'rickroller@rolld.com', '2011-01-05 00:00:00', 10, '4333333333333333');

-- Insert Customer Preferences 
INSERT INTO CustomerPreferences (AccountNo, Preference)
VALUES
(111, 'Window Seat'),
(111, 'Vegetarian Meal'),
(222, 'Aisle Seat'),
(333, 'First Class');

-- Insert Employees 
INSERT INTO Employee (Id, SSN, IsManager, StartDate, HourlyRate)
VALUES
(101, 123456789, FALSE, '2020-01-15', 25.00),
(102, 987654321, FALSE, '2019-06-01', 25.00),
(103, 555555555, TRUE, '2015-03-10', 50.00);

-- Insert Passengers 
INSERT INTO Passenger (Id, AccountNo)
VALUES
(1, 111),  -- Jane Smith can book on account 111
(2, 222),  -- John Doe can book on account 222
(3, 333);  -- Rick Astley can book on account 333

-- Insert Reservations 
INSERT INTO Reservation (ResrNo, ResrDate, BookingFee, TotalFare, RepSSN, AccountNo)
VALUES
(111, '2011-01-05 00:00:00', 120.00, 1200.00, 123456789, 222),  -- John's reservation
(222, '2011-01-10 00:00:00', 50.00, 500.00, 987654321, 111),    -- Jane's reservation
(333, '2011-01-13 00:00:00', 333.33, 3333.33, 123456789, 333);  -- Rick's reservation

-- Insert Includes 
INSERT INTO Includes (ResrNo, AirlineID, FlightNo, LegNo, Date)
VALUES
(111, 'AA', 111, 1, '2011-01-05'),  -- John's first leg
(111, 'AA', 111, 2, '2011-01-05'),  -- John's second leg
(222, 'JB', 111, 2, '2011-01-10'),  -- Jane's flight (just leg 2)
(333, 'AM', 1337, 1, '2011-01-13'); -- Rick's flight

-- Insert ReservationPassenger 
INSERT INTO ReservationPassenger (ResrNo, Id, AccountNo, SeatNo, Class, Meal)
VALUES
(111, 2, 222, '33F', 'Economy', 'Chips'),           -- John Doe
(222, 1, 111, '13A', 'First', 'Fish and Chips'),    -- Jane Smith
(333, 3, 333, '1A', 'First', 'Sushi');              -- Rick Astley

-- Insert Auction/Bid History 
INSERT INTO Auctions (AccountNo, AirlineID, FlightNo, LegNo, Class, Date, NYOP, Accepted)
VALUES
(222, 'AA', 111, 1, 'Economy', '2011-01-04 10:00:00', 400.00, TRUE);  -- John's accepted bid

	-- VERIFICATION QUERIES

SELECT 'Airline' AS TableName, COUNT(*) AS RowCount FROM Airline
UNION ALL
SELECT 'Airport', COUNT(*) FROM Airport
UNION ALL
SELECT 'Flight', COUNT(*) FROM Flight
UNION ALL
SELECT 'Leg', COUNT(*) FROM Leg
UNION ALL
SELECT 'Fare', COUNT(*) FROM Fare
UNION ALL
SELECT 'AdvPurchaseDiscount', COUNT(*) FROM AdvPurchaseDiscount
UNION ALL
SELECT 'Person', COUNT(*) FROM Person
UNION ALL
SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL
SELECT 'CustomerPreferences', COUNT(*) FROM CustomerPreferences
UNION ALL
SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL
SELECT 'Passenger', COUNT(*) FROM Passenger
UNION ALL
SELECT 'Reservation', COUNT(*) FROM Reservation
UNION ALL
SELECT 'Includes', COUNT(*) FROM Includes
UNION ALL
SELECT 'ReservationPassenger', COUNT(*) FROM ReservationPassenger
UNION ALL
SELECT 'Auctions', COUNT(*) FROM Auctions;

