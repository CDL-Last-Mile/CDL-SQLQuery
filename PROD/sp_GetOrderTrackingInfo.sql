USE [CDLData]
GO
/****** Object:  StoredProcedure [dbo].[sp_TrackingPage_GetOrderTrackingInfo]    Script Date: 6/29/2023 7:19:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- =============================================
-- Author:		Vinay
-- Create date: 7/1/2022
-- Description:	Get the order tracking information for order scans when enter ordertracking number or reference number
-- =============================================



--- ===================================================
--- Edit 
---
--- 11/02/2022 --- Dominik -- Change formula 
--- ======================================================
ALTER PROCEDURE [dbo].[sp_TrackingPage_GetOrderTrackingInfo] (@orderTrackingId varchar(50))
AS
BEGIN
    SET NOCOUNT ON;
SET ANSI_WARNINGS on

Declare @ReferenceNumber Varchar(200)

create table #Return
(
OrderTrackingID Decimal(30, 7),
ReferenceNumber Varchar(200),
ShipmentCreated datetime,
TrackingEvents Varchar(200),
DeliveryComplete datetime,
City Varchar(100),
State Varchar(100),
VPOD varbinary(max),
Exception Varchar(100),
ExceptionDetails Varchar(100),
DriverName Varchar(max),
Lat Decimal(30, 8),
long Decimal(30, 8),
DCity Varchar(100),
DState Varchar(100),
DZip Varchar(100),
DStreet Varchar(100),
aTimeStamp datetime,
PODname varchar (50),
SuppressOnCompletion bit,
isAgent bit,
isException bit
)

if exists (select OrderTrackingID  FROM Xcelerator.dbo.xview_orderpackageitems where RefNo=@orderTrackingId)
begin
select  @orderTrackingId=OrderTrackingID, @ReferenceNumber=RefNo FROM Xcelerator.dbo.xview_orderpackageitems where RefNo=@orderTrackingId
end
else
begin 
select @ReferenceNumber=RefNo  FROM Xcelerator.dbo.xview_orderpackageitems where OrderTrackingID=@orderTrackingId
end



--select ssc.Code2, ssc.Details, ossc.aTimeStamp, ssc.SuppressOnCompletion into #tempException from Xcelerator.dbo.xView_OrderShipmentStatusCodes ossc
--left join Xcelerator.dbo.ShipmentStatusCodes ssc on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
--where ossc.OrderTrackingID= @orderTrackingId and ossc.PackageItemID is not null

--Suppression and Exception
select 
	ssc.Code2, ssc.Details, xveml.sTimeStamp as aTimeStamp, ssc.SuppressOnCompletion
	into #tempException
from Xcelerator.dbo.xView_OrderShipmentStatusCodes ossc
	left join Xcelerator.dbo.ShipmentStatusCodes ssc
		on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
	left join Xcelerator.dbo.xView_EventMonitorLog_AllOrders xveml
		on xveml.ordertrackingid=@orderTrackingId
			And ssc.ShipmentStatusCodeID=xveml.ShipmentStatusCodeID
			and xveml.PackageItemID is not null
			and xveml.EventID=2060
	where ossc.OrderTrackingID= @orderTrackingId
		and ossc.PackageItemID is not null


INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, isAgent,isException)
select Top(1) 
@orderTrackingId,
'Label has been created',
(select top(1)sTimeStamp from Xcelerator.dbo.xView_EventMonitorLog_AllOrders where OrderTrackingID=@orderTrackingId and EventID=1000)as aTimeStamp,
t.City,
t.State,
vo.PODname as PODname,
DCity,
DState,
DStreet,
DZip,
vo.oDate,
opi.RefNo,
(select Top 1 Code2 from #tempException order by aTimeStamp DESC),
(select Top 1 Details from #tempException order by aTimeStamp DESC),
1,
(select e.isAgent from Xcelerator.dbo.xview_orderpackageitems opi
LEFT OUTER join Xcelerator.dbo.Employees e 
				ON e.ID = opi.UserID
where opi.OrderTrackingID=@orderTrackingId )
,0
		from Xcelerator.dbo.xView_Orders vo LEFT OUTER JOIN Xcelerator.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID
				LEFT OUTER JOIN Xcelerator.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
				and vosc.PackageItemID is not null
				LEFT OUTER JOIN Xcelerator.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
				INNER JOIN Xcelerator.dbo.terminals t
				ON t.TerminalID = vo.TerminalID 
				where vo.OrderTrackingID=@orderTrackingId
				order by vo.OrderTrackingID desc


----CDL Origin Scan Begin

SELECT DISTINCT 
	vo.OrderTrackingID,
			   opi.RefNo as 'ReferenceNumber',
			   vo.oDate AS 'ShipmentCreated',
			   (CASE
				   WHEN vos.SCANlocation = 'R' THEN
					   'CDL Origin Scan' 
				   WHEN vos.SCANlocation = 'T' THEN
					   'CDL Transfer Scan' 
				   ELSE
					   Null
			   END) AS TrackingEvents,
			   vo.PODcompletion as 'DeliveryComplete',
			   vo.PODname,
			   t.City,
			   t.State,
			   null as 'VPOD',
			   (select Top(1) Code2 from #tempException order by aTimeStamp DESC) as 'Exception',
			   (select Top(1) Details from #tempException order by aTimeStamp DESC) as 'ExceptionDetails',
			   null AS 'DriverName',
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   vos.aTimeStamp as aTimeStamp,
			   (select Top(1) SuppressOnCompletion from #tempException order by aTimeStamp DESC) as SuppressOnCompletion
			 into #tempTable  
		FROM Xcelerator.dbo.xView_Orders vo
			LEFT OUTER JOIN Xcelerator.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			JOIN Xcelerator.dbo.xView_OrderScans vos
				ON vos.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN Xcelerator.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
			--LEFT OUTER JOIN Xcelerator.dbo.xView_EventMonitorLog_AllOrders  xemlao
			--	on xemlao.OrderTrackingID=@orderTrackingId
			--	and xemlao.EventID=2010
			--	and xemlao.PackageItemID=opi.PackageItemID
			LEFT OUTER JOIN Xcelerator.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
			LEFT OUTER join Xcelerator.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join Xcelerator.dbo.Documents d 
				ON d.DocumentID = od.DocumentID
			INNER JOIN Xcelerator.dbo.terminals t
				ON t.TerminalID = vos.TerminalID	
				
			LEFT OUTER join Xcelerator.dbo.Employees e 
				ON e.ID = opi.UserID
			
		WHERE vo.ordertrackingid= @orderTrackingId AND vos.SCANlocation = 'R'
		order by TrackingEvents

Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,SuppressOnCompletion,isException)
select OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion,0 from #tempTable
Drop Table #tempTable 

-----CDL Origin Scan End

-----CDL Transfer Scan Begin 

SELECT DISTINCT 
	vo.OrderTrackingID,
			   opi.RefNo as 'ReferenceNumber',
			   vo.oDate AS 'ShipmentCreated',
			   (CASE
				   WHEN vos.SCANlocation = 'R' THEN
					   'CDL Origin Scan' 
				   WHEN vos.SCANlocation = 'T' THEN
					   'CDL Transfer Scan' 
				   ELSE
					   Null
			   END) AS TrackingEvents,
			   vo.PODcompletion as 'DeliveryComplete',
			   vo.PODname,
			   t.City,
			   t.State,
			   null as 'VPOD',
			    (select Top(1) Code2 from #tempException order by aTimeStamp DESC) as 'Exception',
			   (select Top(1) Details from #tempException order by aTimeStamp DESC) as 'ExceptionDetails',
			   null AS 'DriverName',
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   vos.aTimeStamp as aTimeStamp,
			   (select Top(1) SuppressOnCompletion from #tempException order by aTimeStamp DESC) as SuppressOnCompletion
			 into #tempTable1  
		FROM Xcelerator.dbo.xView_Orders vo
			LEFT OUTER JOIN Xcelerator.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			JOIN Xcelerator.dbo.xView_OrderScans vos
				ON vos.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN Xcelerator.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
			--LEFT OUTER JOIN Xcelerator.dbo.xView_EventMonitorLog_AllOrders xemlao
			--ON xemlao.OrderTrackingID=@orderTrackingId
			--and xemlao.EventID=2015
			--And xemlao.PackageItemID=opi.PackageItemID
			LEFT OUTER JOIN Xcelerator.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
			LEFT OUTER join Xcelerator.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join Xcelerator.dbo.Employees e 
				ON e.ID = opi.UserID 
			left join Xcelerator.dbo.BarcodeDataSets bcds on
			bcds.BarcodeDataSetID=vos.BarcodeDataSetID
			INNER JOIN Xcelerator.dbo.terminals t
				ON t.TerminalID = bcds.Receiving_TerminalID
			
		WHERE vo.ordertrackingid= @orderTrackingId AND vos.SCANlocation = 'T'
		order by TrackingEvents

Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion,isException)
select OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion,0 from #tempTable1
Drop Table #tempTable1

----CDL Transfer Scan END

----Driver In Transit begin

select 
DISTINCT 
		vo.OrderTrackingID,
		opi.RefNo as 'ReferenceNumber',
		vo.oDate AS 'ShipmentCreated',
		'Driver en-route to delivery' AS TrackingEvents,
		vo.PODcompletion as 'DeliveryComplete',
		vo.PODname,
		t.City,
		t.State,
		null as 'VPOD',
		(select Top(1) Code2 from #tempException order by aTimeStamp DESC) as 'Exception',
		(select Top(1) Details from #tempException order by aTimeStamp DESC) as 'ExceptionDetails',
		(select top(1) CONCAT(FirstName, ' ', LastName) from Xcelerator.dbo.xview_OrderDrivers od
		left join Xcelerator.dbo.Employees e
		on e.id=od.DriverID
		where od.OrderTrackingID=vo.ordertrackingid) AS 'DriverName',
		oeg.Lat,
		oeg.long,
		vo.DCity,
		vo.DState,
		vo.DZip,
		vo.DStreet,
		emlao.sTimeStamp as aTimestamp,
		(select Top(1) SuppressOnCompletion from #tempException order by aTimeStamp DESC) as SuppressOnCompletion,
		e.isAgent as isAgent
		 into #tempTable2
		from Xcelerator.dbo.xView_Orders vo
	LEFT OUTER JOIN Xcelerator.dbo.OrderPackages op 
		on op.OrderTrackingID=vo.OrderTrackingID
	LEFT OUTER JOIN Xcelerator.dbo.xview_orderpackageitems opi
		ON opi.OrderTrackingID = vo.OrderTrackingID 
	left outer join Xcelerator.dbo.xView_OrderScans xvos 
	on xvos.OrderTrackingID=@orderTrackingId and xvos.SCANlocation='L'
	LEFT OUTER join Xcelerator.dbo.xView_EventMonitorLog_AllOrders emlao 
		on emlao.OrderTrackingID=vo.OrderTrackingID
	and emlao.EventID in(1007,2011)
	LEFT OUTER join Xcelerator.dbo.Employees e 
		on e.id=emlao.UserID
	LEFT OUTER join Xcelerator.dbo.terminals t
		ON t.TerminalID = vo.TerminalID
	INNER JOIN (select Top(1) * from Xcelerator.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId 
	--and (EventId=1007 or EventId=2011) 
	)oeg on oeg.OrderTrackingID = vo.OrderTrackingID 
	where vo.OrderTrackingID=@orderTrackingId  and ((e.isAgent=0 and emlao.EventID=1007) or (e.isAgent=1 and emlao.EventID=2011) )
		order by vo.OrderTrackingID 


Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,Lat,long, SuppressOnCompletion,isException)
select DISTINCT OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,lat,Long, SuppressOnCompletion,0
from #tempTable2 where TrackingEvents='Driver en-route to delivery'
Drop Table #tempTable2


----Driver In Transit End

--- Delivery begin
-----
Insert into #Return (OrderTrackingID,
ReferenceNumber,
ShipmentCreated,
TrackingEvents,
DeliveryComplete,
PODname,
City,
State,
VPOD,
Exception,
ExceptionDetails,
DriverName,
Lat,
long,
DCity,
DState,
DZip,
DStreet,
aTimeStamp,
SuppressOnCompletion,
isException)

SELECT
	--newid() AS ID,
	vo.OrderTrackingID,
			   opi.RefNo as 'ReferenceNumber',
			   vo.oDate AS 'ShipmentCreated',
			   'Package Scanned At Delivery' AS TrackingEvents,
			   null as 'DeliveryComplete',
			   vo.PODname,
			   vo.DCity as City,
			   vo.DState as State,
			   null as 'VPOD',
			   (select Top(1) Code2 from #tempException order by aTimeStamp DESC) as 'Exception',
			   (select Top(1) Details from #tempException order by aTimeStamp DESC) as 'ExceptionDetails',
			   CONCAT(e.FirstName, ' ', e.LastName) AS 'DriverName',
				oeg.Lat,
			   oeg.long,
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   
			   xvemlao.sTimeStamp as aTimeStamp, 
			   (select Top(1) SuppressOnCompletion from #tempException order by aTimeStamp DESC) as SuppressOnCompletion
			,0
		FROM Xcelerator.dbo.xView_Orders vo
			LEFT OUTER JOIN Xcelerator.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			JOIN Xcelerator.dbo.xView_OrderScans vos
				ON vos.PackageItemID = opi.PackageItemID AND vos.SCANlocation='D'
			LEFT OUTER join Xcelerator.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join Xcelerator.dbo.Documents d 
				ON d.DocumentID = od.DocumentID
			INNER JOIN (select Top(1)* from Xcelerator.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId) oeg
			on oeg.OrderTrackingID = vo.OrderTrackingID 
			left outer join (select Top(1) * from Xcelerator.dbo.xview_eventmonitorlog_allorders xvemlao	where xvemlao.OrderTrackingID=@orderTrackingId and xvemlao.EventID=2013) xvemlao
			on xvemlao.OrderTrackingID=@orderTrackingId and xvemlao.EventID=2013
			INNER JOIN Xcelerator.dbo.terminals t	ON t.TerminalID = vo.TerminalID	
				
			LEFT OUTER join Xcelerator.dbo.Employees e 
				ON e.ID = opi.UserID 
			
		WHERE vos.ordertrackingid= @orderTrackingId 
		order by TrackingEvents

------
---Delivery End

---- Delivery Completed begin 
INSERT INTO #Return(OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,
PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,SuppressOnCompletion,isException)
SELECT 
	vo.OrderTrackingID,
			   opi.RefNo as 'ReferenceNumber',
			   vo.oDate AS 'ShipmentCreated',
			   'Delivery complete' AS TrackingEvents,
			   vo.PODcompletion as 'DeliveryComplete',
			   vo.PODname,
			   vo.DCity as City,
			   vo.DState as State,
			   d.DocumentBinary as 'VPOD',
			   (select Top(1) Code2 from #tempException  order by aTimeStamp DESC) as 'Exception',
			   (select Top(1) Details from #tempException  order by aTimeStamp DESC) as 'ExceptionDetails',
			   
			   eme.Name AS 'DriverName',
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   emlo.sTimeStamp as aTimestamp,
			   (select Top(1) SuppressOnCompletion from #tempException  order by aTimeStamp DESC) as SuppressOnCompletion,
			   0
			   	 
		FROM Xcelerator.dbo.xView_Orders vo
			LEFT OUTER JOIN Xcelerator.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			LEFT OUTER join Xcelerator.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join Xcelerator.dbo.Documents d 
				ON d.DocumentID = od.DocumentID
			left outer join Xcelerator.dbo.xview_eventmonitorlog_allorders emlo
			on emlo.OrderTrackingID=@orderTrackingId
       JOIN Xcelerator.dbo.eventmonitorevents eme
         ON emlo.eventid = eme.eventid
		WHERE vo.ordertrackingid= @orderTrackingId
		and emlo.EventID=1090 and vo.PODcompletion is not null	
		order by TrackingEvents

 		delete r from #Return r where r.aTimeStamp > (select top(1) ossc.aTimeStamp from Xcelerator.dbo.xView_OrderShipmentStatusCodes ossc
		left join Xcelerator.dbo.ShipmentStatusCodes ssc on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
		where ossc.OrderTrackingID= @orderTrackingId and ssc.SuppressOnCompletion=0)



INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, isAgent,isException)
select @orderTrackingId,te.Details,te.aTimeStamp,'','','','','','','','',@ReferenceNumber,te.Code2,te.Details,'','',1 from #tempException te

 ---- Delivery Completed

select ROW_NUMBER() OVER(ORDER BY aTimeStamp desc ) AS id, * from #Return order by aTimeStamp desc

drop Table #tempException
Drop Table #Return

END
