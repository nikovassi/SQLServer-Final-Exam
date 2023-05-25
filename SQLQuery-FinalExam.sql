-- Create Table --

CREATE TABLE Planets 
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(30) NOT NULL
)

CREATE TABLE Spaceports 
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	PlanetId INT REFERENCES Planets(Id) NOT NULL
)

CREATE TABLE Spaceships 
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	Manufacturer VARCHAR(30) NOT NULL,
	LightSpeedRate INT DEFAULT 0
)

CREATE TABLE Colonists 
(
	Id INT PRIMARY KEY IDENTITY,
	[FirstName] VARCHAR(20) NOT NULL,
	[LastName] VARCHAR(20) NOT NULL,
	Ucn VARCHAR(10) UNIQUE NOT NULL,
	BirthDate DATE NOT NULL
)

CREATE TABLE Journeys 
(
	Id INT PRIMARY KEY IDENTITY,
	JourneyStart DATETIME NOT NULL,
	JourneyEnd DATETIME NOT NULL,
	Purpose VARCHAR(11) NOT NULL ,
	DestinationSpaceportId INT REFERENCES Spaceports(Id) NOT NULL,
	SpaceshipId INT REFERENCES Spaceships(Id) NOT NULL
)

CREATE TABLE TravelCards 
(
	Id INT PRIMARY KEY IDENTITY,
	CardNumber VARCHAR(10) UNIQUE NOT NULL,
	JobDuringJourney VARCHAR(8),
	ColonistId INT REFERENCES Colonists(Id) NOT NULL,
	JourneyId INT REFERENCES Journeys(Id) NOT NULL
)

-- Insert --

INSERT INTO [dbo].[Planets]([Name])
	VALUES ('Mars'),
		   ('Earth'),
		   ('Jupiter'),
		   ('Saturn')
	
INSERT INTO [dbo].[Spaceships]([Name], Manufacturer, LightSpeedRate)
	VALUES ('Golf', 'VW', 3),
		   ('WakaWaka', 'Wakanda', 4),
		   ('Falcon9', 'SpaceX', 1),
		   ('Bed', 'Vidolov', 6 )

-- Update --

UPDATE [dbo].[Spaceships]
	SET LightSpeedRate += 1
	WHERE Id BETWEEN 8 AND 12

-- Delete --

DELETE FROM TravelCards
WHERE JourneyId IN (1,2,3)

DELETE FROM Journeys
WHERE Id IN (1,2,3)

-- Select --

SELECT Id, FORMAT(JourneyStart, 'dd/MM/yyyy') AS JourneyStart, 
FORMAT(JourneyEnd, 'dd/MM/yyyy') AS JourneyEnd 
FROM [dbo].[Journeys]
WHERE Purpose = 'Military'
ORDER BY JourneyStart

-- Select and JOIN --

SELECT c.Id, c.FirstName + ' ' + c.LastName AS FullName FROM [dbo].[Colonists] AS c
JOIN [dbo].[TravelCards] AS tc ON c.Id = tc.ColonistId
WHERE JobDuringJourney = 'Pilot'
ORDER BY c.Id ASC

SELECT COUNT(*) as COUNT FROM [dbo].[Colonists] AS c
JOIN [dbo].[TravelCards] AS tc ON c.Id = tc.ColonistId
JOIN [dbo].[Journeys] AS j ON j.Id = tc.JourneyId
WHERE Purpose = 'Technical'

SELECT Name, Manufacturer FROM (SELECT ss.Name, ss.Manufacturer, c.BirthDate, DATEDIFF(YEAR, c.BirthDate, '01/01/2019') AS Age FROM [dbo].[Spaceships] AS ss
		 JOIN [dbo].[Journeys] AS j ON ss.Id = j.SpaceshipId
		 JOIN [dbo].[TravelCards] AS tc ON tc.JourneyId = j.Id
         JOIN [dbo].[Colonists] AS c ON tc.ColonistId = c.Id
		 WHERE JobDuringJourney = 'Pilot'
		 ) AS [spaceships with pilots ]
WHERE Age < 30
ORDER BY Name

 SELECT p.Name AS PlanetName, COUNT(*) AS JourneysCount
	FROM [dbo].[Planets] AS p
	JOIN [dbo].[Spaceports] AS sp ON sp.PlanetId = p.Id
	JOIN [dbo].[Journeys] AS j ON j.DestinationSpaceportId = sp.Id
	GROUP BY p.Name
	ORDER BY JourneysCount DESC, PlanetName

SELECT * FROM 
	   (SELECT JobDuringJourney,
	   FirstName + ' ' + LastName AS FullName,
	   DENSE_RANK() OVER (PARTITION BY JobDuringJourney ORDER BY BirthDate) AS JobRank
       FROM [dbo].[Colonists] AS c
       JOIN [dbo].[TravelCards] AS tc ON tc.ColonistId = c.Id
	   ) AS RankQuery
WHERE JobRank = 2

-- Create function --

CREATE OR ALTER FUNCTION dbo.udf_GetColonistsCount(@PlanetName VARCHAR (30)) 
RETURNS INT
AS
BEGIN 
	IF(@PlanetName IS NULL )
	BEGIN
		RETURN 'NULL'
	END
	DECLARE @COUNT INT;
	SELECT @COUNT = COUNT(*) FROM [dbo].[Planets] AS p
	JOIN [dbo].[Spaceports] AS sr ON sr.PlanetId = p.Id
	JOIN [dbo].[Journeys] AS j ON j.DestinationSpaceportId = sr.Id
	JOIN [dbo].[TravelCards] AS tc ON j.Id = tc.JourneyId
	WHERE p.Name = @PlanetName
	RETURN @COUNT
END

-- Create St. Procedure --

CREATE OR ALTER PROCEDURE usp_ChangeJourneyPurpose(@JourneyId INT, @NewPurpose VARCHAR(50))
AS
BEGIN
	DECLARE @TargetJourneyId INT = (SELECT Id FROM [dbo].[Journeys] 
			WHERE Id = @JourneyId) 
	
	IF(@TargetJourneyId IS NULL)
	BEGIN
		;THROW 55000, 'The journey does not exist!', 1
	END

	DECLARE @CurrentJourneyPurpose VARCHAR(30) = (SELECT Purpose FROM Journeys WHERE Id = @JourneyId)

	IF(@NewPurpose = @CurrentJourneyPurpose)
	BEGIN
		 ;THROW 55000,'You cannot change the purpose!', 2
	END

	UPDATE Journeys
	SET Purpose = @NewPurpose 
	WHERE iD = @JourneyId	
END

