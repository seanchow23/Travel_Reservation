CREATE DATABASE  IF NOT EXISTS `project_2` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `project_2`;
-- MySQL dump 10.13  Distrib 8.0.44, for macos15 (arm64)
--
-- Host: localhost    Database: project_2
-- ------------------------------------------------------
-- Server version	9.5.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '4429bbbe-b35e-11f0-a81c-547a6aa1e9ae:1-967';

--
-- Table structure for table `AdvPurchaseDiscount`
--

DROP TABLE IF EXISTS `AdvPurchaseDiscount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AdvPurchaseDiscount` (
  `AirlineID` char(2) NOT NULL,
  `Days` int NOT NULL,
  `DiscountRate` decimal(10,2) NOT NULL,
  PRIMARY KEY (`AirlineID`,`Days`),
  CONSTRAINT `advpurchasediscount_ibfk_1` FOREIGN KEY (`AirlineID`) REFERENCES `Airline` (`Id`),
  CONSTRAINT `advpurchasediscount_chk_1` CHECK ((`Days` > 0)),
  CONSTRAINT `advpurchasediscount_chk_2` CHECK (((`DiscountRate` >= 0) and (`DiscountRate` <= 100)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AdvPurchaseDiscount`
--

LOCK TABLES `AdvPurchaseDiscount` WRITE;
/*!40000 ALTER TABLE `AdvPurchaseDiscount` DISABLE KEYS */;
INSERT INTO `AdvPurchaseDiscount` VALUES ('AA',7,5.00),('AA',14,10.00),('AA',21,15.00),('AM',14,10.00),('JB',7,7.00),('JB',14,12.00);
/*!40000 ALTER TABLE `AdvPurchaseDiscount` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Airline`
--

DROP TABLE IF EXISTS `Airline`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Airline` (
  `Id` char(2) NOT NULL,
  `Name` varchar(100) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Airline`
--

LOCK TABLES `Airline` WRITE;
/*!40000 ALTER TABLE `Airline` DISABLE KEYS */;
INSERT INTO `Airline` VALUES ('AA','American Airlines'),('AB','Air Berlin'),('AJ','Air Japan'),('AM','Air Madagascar'),('BA','British Airways'),('DL','Delta Airlines'),('JB','JetBlue Airways'),('LH','Lufthansa'),('SW','Southwest Airlines'),('UA','United Airlines');
/*!40000 ALTER TABLE `Airline` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Airport`
--

DROP TABLE IF EXISTS `Airport`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Airport` (
  `Id` char(3) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `City` varchar(50) NOT NULL,
  `Country` varchar(50) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Airport`
--

LOCK TABLES `Airport` WRITE;
/*!40000 ALTER TABLE `Airport` DISABLE KEYS */;
INSERT INTO `Airport` VALUES ('ATL','Hartsfield-Jackson Atlanta Int','Atlanta','United States of America'),('BOS','Logan International','Boston','United States of America'),('HND','Tokyo International','Tokyo','Japan'),('JFK','John F. Kennedy International','New York','United States of America'),('LAX','Los Angeles International','Los Angeles','United States of America'),('LGA','LaGuardia','New York','United States of America'),('LHR','London Heathrow','London','United Kingdom'),('ORD','Chicago O\'Hare International','Chicago','Illinois'),('SFO','San Francisco International','San Francisco','United States of America'),('TNR','Ivato International','Antananarivo','Madagascar'),('TXL','Berlin Tegel','Berlin','Germany');
/*!40000 ALTER TABLE `Airport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Auctions`
--

DROP TABLE IF EXISTS `Auctions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Auctions` (
  `AccountNo` int NOT NULL,
  `AirlineID` char(2) NOT NULL,
  `FlightNo` int NOT NULL,
  `LegNo` int NOT NULL,
  `Class` varchar(20) DEFAULT NULL,
  `Date` datetime NOT NULL,
  `NYOP` decimal(10,2) NOT NULL,
  `Accepted` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`AccountNo`,`AirlineID`,`FlightNo`,`LegNo`,`Date`),
  KEY `AirlineID` (`AirlineID`,`FlightNo`,`LegNo`),
  CONSTRAINT `auctions_ibfk_1` FOREIGN KEY (`AccountNo`) REFERENCES `Customer` (`AccountNo`),
  CONSTRAINT `auctions_ibfk_2` FOREIGN KEY (`AirlineID`, `FlightNo`, `LegNo`) REFERENCES `Leg` (`AirlineID`, `FlightNo`, `LegNo`),
  CONSTRAINT `auctions_chk_1` CHECK ((`NYOP` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Auctions`
--

LOCK TABLES `Auctions` WRITE;
/*!40000 ALTER TABLE `Auctions` DISABLE KEYS */;
INSERT INTO `Auctions` VALUES (222,'AA',111,1,'Economy','2011-01-04 10:00:00',400.00,1);
/*!40000 ALTER TABLE `Auctions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Customer`
--

DROP TABLE IF EXISTS `Customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Customer` (
  `Id` int NOT NULL,
  `AccountNo` int NOT NULL,
  `CreditCardNo` char(16) DEFAULT NULL,
  `Email` varchar(50) DEFAULT NULL,
  `CreationDate` datetime NOT NULL,
  `Rating` int DEFAULT NULL,
  PRIMARY KEY (`AccountNo`),
  KEY `Id` (`Id`),
  CONSTRAINT `customer_ibfk_1` FOREIGN KEY (`Id`) REFERENCES `Person` (`Id`),
  CONSTRAINT `customer_chk_1` CHECK (((`Rating` >= 0) and (`Rating` <= 10)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Customer`
--

LOCK TABLES `Customer` WRITE;
/*!40000 ALTER TABLE `Customer` DISABLE KEYS */;
INSERT INTO `Customer` VALUES (1,111,'4111111111111111','awesomejane@ftw.com','2011-01-05 00:00:00',5),(2,222,'4222222222222222','jdoe@woot.com','2011-01-05 00:00:00',7),(3,333,'4333333333333333','rickroller@rolld.com','2011-01-05 00:00:00',10);
/*!40000 ALTER TABLE `Customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CustomerPreferences`
--

DROP TABLE IF EXISTS `CustomerPreferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CustomerPreferences` (
  `AccountNo` int NOT NULL,
  `Preference` varchar(50) NOT NULL,
  PRIMARY KEY (`AccountNo`,`Preference`),
  CONSTRAINT `customerpreferences_ibfk_1` FOREIGN KEY (`AccountNo`) REFERENCES `Customer` (`AccountNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CustomerPreferences`
--

LOCK TABLES `CustomerPreferences` WRITE;
/*!40000 ALTER TABLE `CustomerPreferences` DISABLE KEYS */;
INSERT INTO `CustomerPreferences` VALUES (111,'Vegetarian Meal'),(111,'Window Seat'),(222,'Aisle Seat'),(333,'First Class');
/*!40000 ALTER TABLE `CustomerPreferences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Employee`
--

DROP TABLE IF EXISTS `Employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Employee` (
  `Id` int NOT NULL,
  `SSN` int NOT NULL,
  `IsManager` tinyint(1) NOT NULL,
  `StartDate` date NOT NULL,
  `HourlyRate` decimal(10,2) NOT NULL,
  PRIMARY KEY (`SSN`),
  UNIQUE KEY `Id` (`Id`),
  CONSTRAINT `employee_ibfk_1` FOREIGN KEY (`Id`) REFERENCES `Person` (`Id`),
  CONSTRAINT `employee_chk_1` CHECK ((`SSN` > 0)),
  CONSTRAINT `employee_chk_2` CHECK ((`HourlyRate` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Employee`
--

LOCK TABLES `Employee` WRITE;
/*!40000 ALTER TABLE `Employee` DISABLE KEYS */;
INSERT INTO `Employee` VALUES (104,111222333,0,'2025-11-01',28.00),(101,123456789,1,'2020-01-15',30.00),(103,555555555,1,'2015-03-10',50.00),(102,987654321,0,'2019-06-01',25.00);
/*!40000 ALTER TABLE `Employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Fare`
--

DROP TABLE IF EXISTS `Fare`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Fare` (
  `AirlineID` char(2) NOT NULL,
  `FlightNo` int NOT NULL,
  `FareType` varchar(20) NOT NULL,
  `Class` varchar(20) NOT NULL,
  `FareAmount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`AirlineID`,`FlightNo`,`FareType`,`Class`),
  CONSTRAINT `fare_ibfk_1` FOREIGN KEY (`AirlineID`, `FlightNo`) REFERENCES `Flight` (`AirlineID`, `FlightNo`),
  CONSTRAINT `fare_chk_1` CHECK ((`FareAmount` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Fare`
--

LOCK TABLES `Fare` WRITE;
/*!40000 ALTER TABLE `Fare` DISABLE KEYS */;
INSERT INTO `Fare` VALUES ('AA',111,'Hidden','Economy',300.00),('AA',111,'OneWay','Business',800.00),('AA',111,'OneWay','Economy',400.00),('AA',111,'OneWay','First',1200.00),('AA',111,'RoundTrip','Economy',750.00),('AM',1337,'Hidden','First',2500.00),('AM',1337,'OneWay','First',3000.00),('JB',111,'Hidden','Economy',200.00),('JB',111,'Hidden','First',400.00),('JB',111,'OneWay','Economy',250.00),('JB',111,'OneWay','First',500.00),('JB',111,'RoundTrip','Economy',450.00);
/*!40000 ALTER TABLE `Fare` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Flight`
--

DROP TABLE IF EXISTS `Flight`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Flight` (
  `AirlineID` char(2) NOT NULL,
  `FlightNo` int NOT NULL,
  `NoOfSeats` int NOT NULL,
  `DaysOperating` char(7) NOT NULL,
  `MinLengthOfStay` int NOT NULL,
  `MaxLengthOfStay` int NOT NULL,
  PRIMARY KEY (`AirlineID`,`FlightNo`),
  CONSTRAINT `flight_ibfk_1` FOREIGN KEY (`AirlineID`) REFERENCES `Airline` (`Id`),
  CONSTRAINT `flight_chk_1` CHECK ((`NoOfSeats` > 0)),
  CONSTRAINT `flight_chk_2` CHECK ((`MinLengthOfStay` >= 0)),
  CONSTRAINT `flight_chk_3` CHECK ((`MaxLengthOfStay` >= `MinLengthOfStay`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Flight`
--

LOCK TABLES `Flight` WRITE;
/*!40000 ALTER TABLE `Flight` DISABLE KEYS */;
INSERT INTO `Flight` VALUES ('AA',111,100,'1010100',0,30),('AM',1337,33,'0000011',3,14),('JB',111,150,'1111111',0,30);
/*!40000 ALTER TABLE `Flight` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Includes`
--

DROP TABLE IF EXISTS `Includes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Includes` (
  `ResrNo` int NOT NULL,
  `AirlineID` char(2) NOT NULL,
  `FlightNo` int NOT NULL,
  `LegNo` int NOT NULL,
  `Date` date NOT NULL,
  PRIMARY KEY (`ResrNo`,`AirlineID`,`FlightNo`,`LegNo`),
  KEY `AirlineID` (`AirlineID`,`FlightNo`,`LegNo`),
  CONSTRAINT `includes_ibfk_1` FOREIGN KEY (`ResrNo`) REFERENCES `Reservation` (`ResrNo`),
  CONSTRAINT `includes_ibfk_2` FOREIGN KEY (`AirlineID`, `FlightNo`, `LegNo`) REFERENCES `Leg` (`AirlineID`, `FlightNo`, `LegNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Includes`
--

LOCK TABLES `Includes` WRITE;
/*!40000 ALTER TABLE `Includes` DISABLE KEYS */;
INSERT INTO `Includes` VALUES (111,'AA',111,1,'2011-01-05'),(111,'AA',111,2,'2011-01-05'),(222,'JB',111,2,'2011-01-10'),(333,'AM',1337,1,'2011-01-13');
/*!40000 ALTER TABLE `Includes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Leg`
--

DROP TABLE IF EXISTS `Leg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Leg` (
  `AirlineID` char(2) NOT NULL,
  `FlightNo` int NOT NULL,
  `LegNo` int NOT NULL,
  `DepAirportID` char(3) NOT NULL,
  `ArrAirportID` char(3) NOT NULL,
  `DepTime` datetime NOT NULL,
  `ArrTime` datetime NOT NULL,
  PRIMARY KEY (`AirlineID`,`FlightNo`,`LegNo`),
  UNIQUE KEY `AirlineID` (`AirlineID`,`FlightNo`,`DepAirportID`),
  KEY `DepAirportID` (`DepAirportID`),
  KEY `ArrAirportID` (`ArrAirportID`),
  CONSTRAINT `leg_ibfk_1` FOREIGN KEY (`AirlineID`, `FlightNo`) REFERENCES `Flight` (`AirlineID`, `FlightNo`),
  CONSTRAINT `leg_ibfk_2` FOREIGN KEY (`DepAirportID`) REFERENCES `Airport` (`Id`),
  CONSTRAINT `leg_ibfk_3` FOREIGN KEY (`ArrAirportID`) REFERENCES `Airport` (`Id`),
  CONSTRAINT `leg_chk_1` CHECK ((`LegNo` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Leg`
--

LOCK TABLES `Leg` WRITE;
/*!40000 ALTER TABLE `Leg` DISABLE KEYS */;
INSERT INTO `Leg` VALUES ('AA',111,1,'LGA','LAX','2011-01-05 11:00:00','2011-01-05 17:00:00'),('AA',111,2,'LAX','HND','2011-01-05 19:00:00','2011-01-06 07:30:00'),('AM',1337,1,'JFK','TNR','2011-01-13 07:00:00','2011-01-14 03:00:00'),('JB',111,1,'SFO','BOS','2011-01-10 14:00:00','2011-01-10 19:30:00'),('JB',111,2,'BOS','LHR','2011-01-10 22:30:00','2011-01-11 05:00:00');
/*!40000 ALTER TABLE `Leg` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Passenger`
--

DROP TABLE IF EXISTS `Passenger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Passenger` (
  `Id` int NOT NULL,
  `AccountNo` int NOT NULL,
  PRIMARY KEY (`Id`,`AccountNo`),
  KEY `AccountNo` (`AccountNo`),
  CONSTRAINT `passenger_ibfk_1` FOREIGN KEY (`Id`) REFERENCES `Person` (`Id`),
  CONSTRAINT `passenger_ibfk_2` FOREIGN KEY (`AccountNo`) REFERENCES `Customer` (`AccountNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Passenger`
--

LOCK TABLES `Passenger` WRITE;
/*!40000 ALTER TABLE `Passenger` DISABLE KEYS */;
INSERT INTO `Passenger` VALUES (1,111),(2,222),(3,333);
/*!40000 ALTER TABLE `Passenger` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Person`
--

DROP TABLE IF EXISTS `Person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Person` (
  `Id` int NOT NULL,
  `FirstName` varchar(50) NOT NULL,
  `LastName` varchar(50) NOT NULL,
  `Address` varchar(100) NOT NULL,
  `City` varchar(50) NOT NULL,
  `State` varchar(50) NOT NULL,
  `ZipCode` int NOT NULL,
  `Phone` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `person_chk_1` CHECK ((`Id` > 0)),
  CONSTRAINT `person_chk_2` CHECK ((`ZipCode` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Person`
--

LOCK TABLES `Person` WRITE;
/*!40000 ALTER TABLE `Person` DISABLE KEYS */;
INSERT INTO `Person` VALUES (1,'Jane','Smith','100 Nicolls Rd','Stony Brook','NY',11790,'555-555-5555'),(2,'John','Doe','123 N Fake Street','New York','NY',10001,'123-123-1234'),(3,'Rick','Astley','1337 Internet Lane','Los Angeles','CA',90001,'314-159-2653'),(101,'Alice','Johnson','50 Union Ave','Stony Brook','NY',11790,'631-555-9999'),(102,'Bob','Williams','75 Main St','Port Jefferson','NY',11777,'631-555-0002'),(103,'Carol','Manager','100 Admin Blvd','Stony Brook','NY',11790,'631-555-0003'),(104,'David','Brown','200 Oak Street','Stony Brook','NY',11790,'631-555-0004');
/*!40000 ALTER TABLE `Person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Reservation`
--

DROP TABLE IF EXISTS `Reservation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Reservation` (
  `ResrNo` int NOT NULL,
  `ResrDate` datetime NOT NULL,
  `BookingFee` decimal(10,2) NOT NULL,
  `TotalFare` decimal(10,2) NOT NULL,
  `RepSSN` int DEFAULT NULL,
  `AccountNo` int NOT NULL,
  PRIMARY KEY (`ResrNo`),
  KEY `RepSSN` (`RepSSN`),
  KEY `AccountNo` (`AccountNo`),
  CONSTRAINT `reservation_ibfk_1` FOREIGN KEY (`RepSSN`) REFERENCES `Employee` (`SSN`),
  CONSTRAINT `reservation_ibfk_2` FOREIGN KEY (`AccountNo`) REFERENCES `Customer` (`AccountNo`),
  CONSTRAINT `reservation_chk_1` CHECK ((`ResrNo` > 0)),
  CONSTRAINT `reservation_chk_2` CHECK ((`BookingFee` > 0)),
  CONSTRAINT `reservation_chk_3` CHECK ((`TotalFare` >= `BookingFee`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Reservation`
--

LOCK TABLES `Reservation` WRITE;
/*!40000 ALTER TABLE `Reservation` DISABLE KEYS */;
INSERT INTO `Reservation` VALUES (111,'2011-01-05 00:00:00',120.00,1200.00,123456789,222),(222,'2011-01-10 00:00:00',50.00,500.00,987654321,111),(333,'2011-01-13 00:00:00',333.33,3333.33,123456789,333);
/*!40000 ALTER TABLE `Reservation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ReservationPassenger`
--

DROP TABLE IF EXISTS `ReservationPassenger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ReservationPassenger` (
  `ResrNo` int NOT NULL,
  `Id` int NOT NULL,
  `AccountNo` int NOT NULL,
  `SeatNo` char(5) NOT NULL,
  `Class` varchar(20) NOT NULL,
  `Meal` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`ResrNo`,`Id`,`AccountNo`),
  KEY `Id` (`Id`,`AccountNo`),
  CONSTRAINT `reservationpassenger_ibfk_1` FOREIGN KEY (`ResrNo`) REFERENCES `Reservation` (`ResrNo`),
  CONSTRAINT `reservationpassenger_ibfk_2` FOREIGN KEY (`Id`, `AccountNo`) REFERENCES `Passenger` (`Id`, `AccountNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ReservationPassenger`
--

LOCK TABLES `ReservationPassenger` WRITE;
/*!40000 ALTER TABLE `ReservationPassenger` DISABLE KEYS */;
INSERT INTO `ReservationPassenger` VALUES (111,2,222,'33F','Economy','Chips'),(222,1,111,'13A','First','Fish and Chips'),(333,3,333,'1A','First','Sushi');
/*!40000 ALTER TABLE `ReservationPassenger` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-03 22:17:55
