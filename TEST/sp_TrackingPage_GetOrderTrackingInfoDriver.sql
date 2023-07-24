USE [CDLData]
GO
/****** Object:  StoredProcedure [dbo].[sp_TrackingPage_GetOrderTrackingInfoDriver]    Script Date: 6/15/2023 8:38:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_TrackingPage_GetOrderTrackingInfoDriver] (@orderTrackingId varchar(50))
AS
BEGIN
    SET NOCOUNT ON;
SET ANSI_WARNINGS on



--if exists (select OrderTrackingID  FROM XceleratorTest.dbo.orderpackageitems where RefNo=@orderTrackingId)
--begin
--select  @orderTrackingId=OrderTrackingID  FROM XceleratorTest.dbo.orderpackageitems where RefNo=@orderTrackingId
--end

select top(1) 1 as Id, Long,Lat from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId order by LocalUTC desc
--select Top(1) 1 as Id,  gps.GeoLocation.Long as Long, gps.GeoLocation.Lat as Lat from XceleratorTest.dbo.OrderDrivers od
--left join XceleratorTest.dbo.Employees e
--on e.id=od.DriverID
--left join XceleratorTest.dbo.GPSlog gps
--on e.ID=gps.DriverID
--where od.OrderTrackingID=@orderTrackingId
----and gps.aTimeStamp >=  DateAdd(Hour, DateDiff(Hour, 0, GetDate())-12, 0)
--order by gps.aTimeStamp desc 



END
