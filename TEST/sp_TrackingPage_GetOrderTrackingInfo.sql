USE [CDLData]
GO
/****** Object:  StoredProcedure [dbo].[sp_TrackingPage_GetOrderTrackingInfo]    Script Date: 6/15/2023 6:13:17 PM ******/
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
isAgent bit
)

if exists (select OrderTrackingID  FROM XceleratorTest.dbo.xview_orderpackageitems where RefNo=@orderTrackingId)
begin
select  @orderTrackingId=OrderTrackingID  FROM XceleratorTest.dbo.xview_orderpackageitems where RefNo=@orderTrackingId
end


select ssc.Code2, ssc.Details, ossc.aTimeStamp, ssc.SuppressOnCompletion into #tempException from XceleratorTest.dbo.xView_OrderShipmentStatusCodes ossc
left join XceleratorTest.dbo.ShipmentStatusCodes ssc on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
where ossc.OrderTrackingID= @orderTrackingId and ossc.PackageItemID is not null



INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, isAgent)
select Top(1) @orderTrackingId,'Label has been created', vo.oDate as aTimestamp,t.City,t.State,
vo.PODname as PODname,
DCity,DState,DStreet, DZip,vo.oDate,opi.RefNo,(select Top 1 Code2 from #tempException order by aTimeStamp DESC),
(select Top 1 Details from #tempException order by aTimeStamp DESC), 1,
(select e.isAgent from XceleratorTest.dbo.xview_orderpackageitems opi
LEFT OUTER join XceleratorTest.dbo.Employees e 
				ON e.ID = opi.UserID
where opi.OrderTrackingID=@orderTrackingId )
		from XceleratorTest.dbo.xView_Orders vo LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID
				LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
				and vosc.PackageItemID is not null
				LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
				INNER JOIN XceleratorTest.dbo.terminals t
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
			   (select Code2 from #tempException) as 'Exception',
			   (select Details from #tempException) as 'ExceptionDetails',
			   null AS 'DriverName',
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   vos.aTimeStamp,
			   (select SuppressOnCompletion from #tempException) as SuppressOnCompletion
			 into #tempTable  
		FROM XceleratorTest.dbo.xView_Orders vo
			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			JOIN XceleratorTest.dbo.xView_OrderScans vos
				ON vos.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join XceleratorTest.dbo.Documents d 
				ON d.DocumentID = od.DocumentID
			INNER JOIN XceleratorTest.dbo.terminals t
				ON t.TerminalID = vos.TerminalID	
				
			LEFT OUTER join XceleratorTest.dbo.Employees e 
				ON e.ID = opi.UserID
			
		WHERE vo.ordertrackingid= @orderTrackingId AND vos.SCANlocation = 'R'
		order by TrackingEvents

Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,SuppressOnCompletion) select OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion from #tempTable
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
			    (select Code2 from #tempException) as 'Exception',
			   (select Details from #tempException) as 'ExceptionDetails',
			   null AS 'DriverName',
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   vos.aTimeStamp,
			   (select SuppressOnCompletion from #tempException) as SuppressOnCompletion
			 into #tempTable1  
		FROM XceleratorTest.dbo.xView_Orders vo
			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			JOIN XceleratorTest.dbo.xView_OrderScans vos
				ON vos.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join XceleratorTest.dbo.Employees e 
				ON e.ID = opi.UserID 
			left join XceleratorTest.dbo.BarcodeDataSets bcds on
			bcds.BarcodeDataSetID=vos.BarcodeDataSetID
			INNER JOIN XceleratorTest.dbo.terminals t
				ON t.TerminalID = bcds.Receiving_TerminalID
			
		WHERE vo.ordertrackingid= @orderTrackingId AND vos.SCANlocation = 'T'
		order by TrackingEvents

Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion) select OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion from #tempTable1
Drop Table #tempTable1

----CDL Transfer Scan END

----Driver In Transit begin


--SELECT  DISTINCT 
--	vo.OrderTrackingID,
--			   opi.RefNo as 'ReferenceNumber',
--			   vo.oDate AS 'ShipmentCreated',
--			   (CASE
 
--				   WHEN (e.isAgent = 0 AND oeg.EventID = 1007) OR
--						(e.isAgent = 1 AND oeg.EventID = 2011) THEN 
--					   'Driver en-route to delivery' 
--				   ELSE
--					   Null
--			   END) AS TrackingEvents,
--			   vo.PODcompletion as 'DeliveryComplete',
--			   vo.PODname,
--			   t.City,
--			   t.State,
--			   null as 'VPOD',
--			    (select Code2 from #tempException) as 'Exception',
--			   (select Details from #tempException) as 'ExceptionDetails',
--			   (select top(1) CONCAT(FirstName, ' ', LastName) from XceleratorTest.dbo.OrderDrivers od
--left join XceleratorTest.dbo.Employees e
--on e.id=od.DriverID
--where od.OrderTrackingID=@orderTrackingId)
--			   AS 'DriverName',
--				oeg.Lat,
--				oeg.long,
--			   vo.DCity,
--			   vo.DState,
--			   vo.DZip,
--			   vo.DStreet,
--			   oeg.ServerTimeStamp as aTimestamp,
--			   (select SuppressOnCompletion from #tempException) as SuppressOnCompletion,
--			   e.isAgent as isAgent
--			 into #tempTable2  
--		FROM XceleratorTest.dbo.xView_Orders vo
--			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID 
--			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
--				ON od.OrderTrackingID = vo.OrderTrackingID
--			LEFT OUTER join XceleratorTest.dbo.Documents d 
--				ON d.DocumentID = od.DocumentID
--			INNER JOIN XceleratorTest.dbo.xView_OrderEventGPS oeg
--			on oeg.OrderTrackingID = vo.OrderTrackingID and (EventID  in (1007, 2011) )

--			INNER JOIN XceleratorTest.dbo.terminals t	ON t.TerminalID = vo.TerminalID	
--			LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON (e.DriverNo = opi.UserID) or e.DriverNo =(select UserID from xceleratorTest.dbo.OrderScans where OrderTrackingID=@orderTrackingId)

--		WHERE vo.ordertrackingid=@orderTrackingId 
--		and ((e.isAgent = 0 AND oeg.EventID = 1007) OR (e.isAgent = 1 AND oeg.EventID = 2011 AND (select COUNT( OrderTrackingID) from XceleratorTest.dbo.OrderScans where OrderTrackingID=@orderTrackingId AND SCANlocation='L')>0))
--		order by TrackingEvents

--SELECT  
--DISTINCT 
--	vo.OrderTrackingID,
--			   opi.RefNo as 'ReferenceNumber',
--			   vo.oDate AS 'ShipmentCreated',
 
--					   'Driver en-route to delivery' 
-- AS TrackingEvents,
--			   vo.PODcompletion as 'DeliveryComplete',
--			   vo.PODname,
--			   t.City,
--			   t.State,
--			   null as 'VPOD',
--			    '' as 'Exception',
--			   '' as 'ExceptionDetails',
--			   (select top(1) CONCAT(FirstName, ' ', LastName) from XceleratorTest.dbo.xview_OrderDrivers od
--left join XceleratorTest.dbo.Employees e
--on e.id=od.DriverID
--where od.OrderTrackingID=vo.ordertrackingid)
--			   AS 'DriverName',
--				oeg.Lat,
--				oeg.long,
--			   vo.DCity,
--			   vo.DState,
--			   vo.DZip,
--			   vo.DStreet,
--			   oeg.ServerTimeStamp as aTimestamp,
--			   '' as SuppressOnCompletion,
--			   e.isAgent as isAgent
--			 into #tempTable2  
--		FROM XceleratorTest.dbo.xView_Orders vo
--			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID 
--			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments xod 
--				ON xod.OrderTrackingID = vo.OrderTrackingID
--			LEFT OUTER join XceleratorTest.dbo.Documents d 
--				ON d.DocumentID = xod.DocumentID
--			INNER JOIN XceleratorTest.dbo.xView_OrderEventGPS oeg
--			on oeg.OrderTrackingID = vo.OrderTrackingID and (oeg.EventID = 1007 or oeg.EventID = 2011 )
--			INNER JOIN XceleratorTest.dbo.terminals t
--				ON t.TerminalID = vo.TerminalID
--			inner join XceleratorTest.dbo.xview_Orderdrivers od
--			on od.OrderTrackingID=vo.OrderTrackingID
--			LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON e.id = od.DriverID
--		WHERE vo.ordertrackingid=@orderTrackingId 
--		and (e.isAgent = 0 AND oeg.EventID = 1007)
--		or ((e.isAgent = 1 AND oeg.EventID = 1007)
--		and (select COUNT( OrderTrackingID) from XceleratorTest.dbo.OrderScans where OrderTrackingID=@orderTrackingId and SCANlocation='L')>0)
--		----order by TrackingEvents

--select 
--DISTINCT 
--		vo.OrderTrackingID,
--		opi.RefNo as 'ReferenceNumber',
--		vo.oDate AS 'ShipmentCreated',
--		'Driver en-route to delivery' AS TrackingEvents,
--		vo.PODcompletion as 'DeliveryComplete',
--		vo.PODname,
--		t.City,
--		t.State,
--		null as 'VPOD',
--		'' as 'Exception',
--		'' as 'ExceptionDetails',
--		(select top(1) CONCAT(FirstName, ' ', LastName) from XceleratorTest.dbo.xview_OrderDrivers od
--		left join XceleratorTest.dbo.Employees e
--		on e.id=od.DriverID
--		where od.OrderTrackingID=vo.ordertrackingid)
--		AS 'DriverName',
--		oeg.Lat,
--		oeg.long,
--		vo.DCity,
--		vo.DState,
--		vo.DZip,
--		vo.DStreet,
--		oeg.ServerTimeStamp as aTimestamp,
--		'' as SuppressOnCompletion,
--		e.isAgent as isAgent
--		 into #tempTable2
--		from XceleratorTest.dbo.xView_Orders vo
--	LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderPackages op 
--		on op.OrderTrackingID=vo.OrderTrackingID
--	LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--		ON opi.OrderTrackingID = vo.OrderTrackingID 
--	LEFT OUTER join XceleratorTest.dbo.xView_EventMonitorLog_AllOrders emlao 
--		on emlao.OrderTrackingID=vo.OrderTrackingID
--	and emlao.EventID in(1007,2011)
--	LEFT OUTER join XceleratorTest.dbo.Employees e 
--		on e.id=emlao.UserID
--	LEFT OUTER join XceleratorTest.dbo.terminals t
--		ON t.TerminalID = vo.TerminalID
--	INNER JOIN (select Top(1) * from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId order by LocalUTC desc) oeg on oeg.OrderTrackingID = vo.OrderTrackingID 
--	where vo.OrderTrackingID=@orderTrackingId  and ((e.isAgent=0 and emlao.EventID=1007) or (e.isAgent=1 and emlao.EventID=2011) )
--		order by vo.OrderTrackingID 

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
		(select Code2 from #tempException) as 'Exception',
		(select Details from #tempException) as 'ExceptionDetails',
		(select top(1) CONCAT(FirstName, ' ', LastName) from XceleratorTest.dbo.xview_OrderDrivers od
		left join XceleratorTest.dbo.Employees e
		on e.id=od.DriverID
		where od.OrderTrackingID=vo.ordertrackingid) AS 'DriverName',
		oeg.Lat,
		oeg.long,
		vo.DCity,
		vo.DState,
		vo.DZip,
		vo.DStreet,
		oeg.ServerTimeStamp as aTimestamp,
		'' as SuppressOnCompletion,
		e.isAgent as isAgent
		 into #tempTable2
		from XceleratorTest.dbo.xView_Orders vo
	LEFT OUTER JOIN XceleratorTest.dbo.OrderPackages op 
		on op.OrderTrackingID=vo.OrderTrackingID
	LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
		ON opi.OrderTrackingID = vo.OrderTrackingID 
	LEFT OUTER join XceleratorTest.dbo.xView_EventMonitorLog_AllOrders emlao 
		on emlao.OrderTrackingID=vo.OrderTrackingID
	and emlao.EventID in(1007,2011)
	LEFT OUTER join XceleratorTest.dbo.Employees e 
		on e.id=emlao.UserID
	LEFT OUTER join XceleratorTest.dbo.terminals t
		ON t.TerminalID = vo.TerminalID
	INNER JOIN (select Top(1) * from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId order by LocalUTC desc) oeg on oeg.OrderTrackingID = vo.OrderTrackingID 
	where vo.OrderTrackingID=@orderTrackingId  and ((e.isAgent=0 and emlao.EventID=1007) or (e.isAgent=1 and emlao.EventID=2011) )
		order by vo.OrderTrackingID 


Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,Lat,long, SuppressOnCompletion) select DISTINCT OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,lat,Long, SuppressOnCompletion
from #tempTable2 where TrackingEvents='Driver en-route to delivery'
Drop Table #tempTable2


----Driver In Transit End

--- Delivery begin
-----
SELECT  DISTINCT 
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
			    (select Code2 from #tempException) as 'Exception',
			   (select Details from #tempException) as 'ExceptionDetails',
			   CONCAT(e.FirstName, ' ', e.LastName) AS 'DriverName',
				oeg.Lat,
			   oeg.long,
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   --gl.GeoLocation,
			   vos.aTimeStamp as aTimeStamp,
			   (select SuppressOnCompletion from #tempException) as SuppressOnCompletion
			 into #tempTable3  
		FROM XceleratorTest.dbo.xView_Orders vo
			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			JOIN XceleratorTest.dbo.xView_OrderScans vos
				ON vos.PackageItemID = opi.PackageItemID AND vos.SCANlocation='D'
			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
				ON vosc.PackageItemID = opi.PackageItemID
			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join XceleratorTest.dbo.Documents d 
				ON d.DocumentID = od.DocumentID
			INNER JOIN XceleratorTest.dbo.xView_OrderEventGPS oeg
			on oeg.OrderTrackingID = vo.OrderTrackingID and ( EventID in(1090,2013))
			--INNER JOIN XceleratorTest.dbo.terminals t	ON t.TerminalID = vo.TerminalID	
				
			LEFT OUTER join XceleratorTest.dbo.Employees e 
				ON e.ID = opi.UserID 
			
		WHERE vos.ordertrackingid= @orderTrackingId -- and (vos.SCANlocation = 'D') 
		order by TrackingEvents
select Distinct aTimeStamp into #tempTable4 from #tempTable3 where TrackingEvents='Package scanned at delivery'
select ROW_NUMBER() OVER(ORDER BY aTimeStamp) AS num_row, * into #tempTable5 from #tempTable4

select DISTINCT OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,t3.Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,SuppressOnCompletion,Long, Lat
into #tempTable6 from #tempTable3 t3
--where TrackingEvents='Package scanned at delivery'
select ROW_NUMBER() OVER(ORDER BY TrackingEvents) AS num_row, * into #tempTable7 from #tempTable6
Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion,long,Lat) 
select OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp, SuppressOnCompletion, Long,Lat from #tempTable5 b,#tempTable7 a where a.num_row=b.num_row
	Drop Table #tempTable3
	Drop Table #tempTable4
	Drop Table #tempTable5
	Drop Table #tempTable6
	Drop Table #tempTable7

------
---Delivery End

---- Delivery Completed begin 
INSERT INTO #Return(OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,
PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,SuppressOnCompletion)
SELECT --top(1)
	--newid() AS ID,
	vo.OrderTrackingID,
			   opi.RefNo as 'ReferenceNumber',
			   vo.oDate AS 'ShipmentCreated',
			   'Delivery complete' AS TrackingEvents,
			   vo.PODcompletion as 'DeliveryComplete',
			   vo.PODname,
			   vo.DCity as City,
			   vo.DState as State,
			   d.DocumentBinary as 'VPOD',
			   (select Code2 from #tempException) as 'Exception',
			   (select Details from #tempException) as 'ExceptionDetails',
			   --CONCAT(e.FirstName, ' ', e.LastName)
			   eme.Name AS 'DriverName',
			   vo.DCity,
			   vo.DState,
			   vo.DZip,
			   vo.DStreet,
			   vo.PODcompletion as aTimestamp,
			   (select SuppressOnCompletion from #tempException) as SuppressOnCompletion
			   	 
		FROM XceleratorTest.dbo.xView_Orders vo
			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
				ON opi.OrderTrackingID = vo.OrderTrackingID 
			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
				ON od.OrderTrackingID = vo.OrderTrackingID
			LEFT OUTER join XceleratorTest.dbo.Documents d 
				ON d.DocumentID = od.DocumentID
			left outer join XceleratorTest.dbo.xview_eventmonitorlog_allorders emlo
			on emlo.OrderTrackingID=@orderTrackingId
       JOIN XceleratorTest.dbo.eventmonitorevents eme
         ON emlo.eventid = eme.eventid
		WHERE vo.ordertrackingid= @orderTrackingId
		and emlo.EventID=1090 and vo.PODcompletion is not null	
		order by TrackingEvents






----v1 begin 
--Insert into #Return (OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,SuppressOnCompletion,Lat,long)
--SELECT top(1)
--	--newid() AS ID,
--	vo.OrderTrackingID,
--			   opi.RefNo as 'ReferenceNumber',
--			   vo.oDate AS 'ShipmentCreated',
--			   (CASE
--				   WHEN vos.SCANlocation = 'D' OR oeg.EventID = 1090 THEN
--					   'Delivery complete'
--				   ELSE
--					   Null
--			   END) AS TrackingEvents,
--			   vo.PODcompletion as 'DeliveryComplete',
--			   vo.PODname,
--			   vo.DCity as City,
--			   vo.DState as State,
--			   d.DocumentBinary as 'VPOD',
--			    (select Code2 from #tempException) as 'Exception',
--			   (select Details from #tempException) as 'ExceptionDetails',
--			   CONCAT(e.FirstName, ' ', e.LastName) AS 'DriverName',

--			   vo.DCity,
--			   vo.DState,
--			   vo.DZip,
--			   vo.DStreet,

--			   vo.PODcompletion as aTimestamp,
--			   (select SuppressOnCompletion from #tempException) as SuppressOnCompletion,
--			   oeg.Lat,
--			   oeg.Long
			 
--		FROM XceleratorTest.dbo.xView_Orders vo
--			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID 
--			JOIN XceleratorTest.dbo.xView_OrderScans vos
--				ON vos.PackageItemID = opi.PackageItemID
--			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
--				ON od.OrderTrackingID = vo.OrderTrackingID
--			LEFT OUTER join XceleratorTest.dbo.Documents d 
--				ON d.DocumentID = od.DocumentID
--			INNER JOIN XceleratorTest.dbo.xView_OrderEventGPS oeg
--			on oeg.OrderTrackingID = vo.OrderTrackingID AND (EventID in (1007,2011,1090))

--			INNER JOIN XceleratorTest.dbo.terminals t
--				ON t.TerminalID = vo.TerminalID	
				
--			LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON e.ID = oeg.UserID 

			
--		WHERE vos.ordertrackingid= @orderTrackingId AND (vos.SCANlocation = 'D' OR oeg.EventID = 1090)
--		order by TrackingEvents

--INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, DeliveryComplete)
--select @orderTrackingId,'Delivery complete', vo.PODcompletion,DCity,DState, vo.PODname, DCity,DState,DStreet, DZip,vo.oDate,opi.RefNo,(select Code2 from #tempException),(select Details from #tempException), (select SuppressOnCompletion from #tempException), vo.PODcompletion
--		from XceleratorTest.dbo.xView_Orders vo
--		LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID
--				LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--				LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--				INNER JOIN XceleratorTest.dbo.terminals t
--				ON t.TerminalID = vo.TerminalID where vo.OrderTrackingID=@orderTrackingId and exists
--				(	select * from XceleratorTest.dbo.xview_EventMonitorLog_Orders emlo
--join XceleratorTest.dbo.EventMonitorLog eml on eml.LogID=emlo.LogID

--where emlo.OrderTrackingID=@orderTrackingId and eml.EventId=1090) and 
--not exists (
--select 1 FROM XceleratorTest.dbo.xView_Orders vo
--			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID 
--			JOIN XceleratorTest.dbo.xView_OrderScans vos
--				ON vos.PackageItemID = opi.PackageItemID
--				where vo.OrderTrackingID=@orderTrackingId
--) and vo.PODcompletion is not null


----end v1




--if(select count(*)from #Return)=1
--begin
--INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, isAgent,DeliveryComplete)
--select @orderTrackingId,'Delivery complete', vo.PODcompletion as aTimestamp,t.City,t.State,
--vo.PODname as PODname,
--DCity,DState,DStreet, DZip,vo.oDate,opi.RefNo,(select Code2 from #tempException),
--(select Details from #tempException), 1,
--(select e.isAgent from XceleratorTest.dbo.xview_orderpackageitems opi
--LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON e.ID = opi.UserID
--where opi.OrderTrackingID=@orderTrackingId ),
--vo.PODcompletion
--		from XceleratorTest.dbo.xView_Orders vo LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID
--				LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--				LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--				INNER JOIN XceleratorTest.dbo.terminals t
--				ON t.TerminalID = vo.TerminalID where vo.OrderTrackingID=@orderTrackingId

--end


---- Delivery Completed end


--- EXCEPTION begin



--select DISTINCT ssc.Code2, ossc.aTimeStamp into #temptable9 from XceleratorTest.dbo.xView_OrderShipmentStatusCodes ossc
--left join XceleratorTest.dbo.ShipmentStatusCodes ssc on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
--where ossc.OrderTrackingID=@orderTrackingId


INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, isAgent)
select @orderTrackingId,te.Details,te.aTimeStamp,'','','','','','','','','',te.Details,te.Code2,'','' from #tempException te
--INSERT INTO #Return(OrderTrackingID,TrackingEvents,aTimeStamp,City,State, PODname, DCity,DState,DStreet,DZip, ShipmentCreated, ReferenceNumber,Exception,ExceptionDetails, SuppressOnCompletion, isAgent)
--select @orderTrackingId,(select top(1) code2 from #tempException), vosc.aTimeStamp as aTimestamp,'','',
--vo.PODname as PODname,
--DCity,DState,DStreet, DZip,vo.oDate,opi.RefNo,(select Code2 from #tempException),
--(select Details from #tempException), (select SuppressOnCompletion from #tempException),
--(select e.isAgent from XceleratorTest.dbo.xview_orderpackageitems opi
--LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON e.ID = opi.UserID
--where opi.OrderTrackingID=@orderTrackingId )
--		from XceleratorTest.dbo.xView_Orders vo LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID
--				LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--				LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--				INNER JOIN XceleratorTest.dbo.terminals t
--				ON t.TerminalID = vo.TerminalID 
--				where vo.OrderTrackingID=@orderTrackingId and exists (select Code2 from #tempException)

--select * from #Return

----suppression begin

--		delete r from #Return r where r.aTimeStamp > (select top(1) ossc.aTimeStamp from XceleratorTest.dbo.xView_OrderShipmentStatusCodes ossc
--		left join XceleratorTest.dbo.ShipmentStatusCodes ssc on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
--		where ossc.OrderTrackingID= @orderTrackingId and ssc.SuppressOnCompletion=0)
----suppression end

				

--- EXCEPTION end






--select ROW_NUMBER() OVER(ORDER BY aTimeStamp desc ) AS id,

--* into #temptable8 from #Return 


 

select ROW_NUMBER() OVER(ORDER BY aTimeStamp desc ) AS id, * from #Return order by aTimeStamp desc
--Drop Table #temptable8
drop Table #tempException
Drop Table #Return

END
