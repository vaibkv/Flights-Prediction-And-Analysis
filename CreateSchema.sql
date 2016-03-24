Use _flights;

IF NOT EXISTS (
SELECT  schema_name
FROM    information_schema.schemata
WHERE   schema_name = 'data' )
BEGIN
EXEC sp_executesql N'CREATE SCHEMA data'
END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[flights]') AND type in (N'U'))
BEGIN
CREATE TABLE [data].[flights](
 [flights_Key] int IDENTITY(1,1) NOT NULL,
 FL_DATE date,
 CARRIER varchar(10),
 FL_NUM varchar(10),
 ORIGIN_AIRPORT_ID int,
 ORIGIN varchar(10),
 DEST_AIRPORT_ID int,
 DEST varchar(10),
 CRS_DEP_TIME varchar(4),
 DEP_TIME varchar(4),
 TAXI_OUT float,
 WHEELS_OFF varchar(4),
 WHEELS_ON varchar(4),
 TAXI_IN float,
 CRS_ARR_TIME varchar(4),
 ARR_TIME varchar(4),
 CANCELLED float,
 CANCELLATION_CODE varchar(4),
 DIVERTED float,
 DISTANCE float,
 CARRIER_DELAY float,
 WEATHER_DELAY float,
 NAS_DELAY float,
 SECURITY_DELAY float,
 LATE_AIRCRAFT_DELAY float,
 CONSTRAINT [PK_flights_Key] PRIMARY KEY CLUSTERED 
(
 [flights_Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
END

IF  NOT EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[OriginDestinationCodes]') AND type in (N'U'))
BEGIN
CREATE TABLE [data].[OriginDestinationCodes](
 [OriginDestinationCodes_Key] int IDENTITY(1,1) NOT NULL,
 Code varchar(10),
 [Description] varchar(200),
 CONSTRAINT [PK_OriginDestinationCodes_key] PRIMARY KEY CLUSTERED 
(
 [OriginDestinationCodes_Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
END


IF  NOT EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[CancellationCodes]') AND type in (N'U'))
BEGIN
CREATE TABLE [data].[CancellationCodes](
 [CancellationCodes_Key] int IDENTITY(1,1) NOT NULL,
 Code varchar(2),
 [Description] varchar(50),
 CONSTRAINT [PK_CancellationCodes_Key] PRIMARY KEY CLUSTERED 
(
 [CancellationCodes_Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
END

IF  NOT EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[AirportIDs]') AND type in (N'U'))
BEGIN
CREATE TABLE [data].[AirportIDs](
 [AirportIDs_Key] int IDENTITY(1,1) NOT NULL,
 Code varchar(10),
 [Description] varchar(200),
 CONSTRAINT [PK_AirportIDs_Key] PRIMARY KEY CLUSTERED 
(
 [AirportIDs_Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
END