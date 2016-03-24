use _flights;

IF  EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[flights]') AND type in (N'U'))
BEGIN
drop table [data].[flights]
END

IF  EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[OriginDestinationCodes]') AND type in (N'U'))
BEGIN
drop table [data].[OriginDestinationCodes]
END

IF  EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[CancellationCodes]') AND type in (N'U'))
BEGIN
drop table [data].[CancellationCodes]
END

IF  EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[data].[AirportIDs]') AND type in (N'U'))
BEGIN
drop table [data].[AirportIDs]
END