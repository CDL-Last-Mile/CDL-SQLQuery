USE [Xcelerator]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetOrderTrackingInfoDriver]    Script Date: 3/16/2023 2:50:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_GetOrderTrackingInfoDriver] (@orderTrackingId varchar(50))
AS
BEGIN
    SET NOCOUNT ON;
SET ANSI_WARNINGS on



if exists (select OrderTrackingID  FROM dbo.orderpackageitems where RefNo=@orderTrackingId)
begin
select  @orderTrackingId=OrderTrackingID  FROM dbo.orderpackageitems where RefNo=@orderTrackingId
end


select Top(1) 1 as Id,  gps.GeoLocation.Long as Long, gps.GeoLocation.Lat as Lat from OrderDrivers od
left join Employees e
on e.id=od.DriverID
left join GPSlog gps
on e.ID=gps.DriverID
where od.OrderTrackingID=@orderTrackingId
--and gps.aTimeStamp >=  DateAdd(Hour, DateDiff(Hour, 0, GetDate())-12, 0)
order by gps.aTimeStamp desc 



END
