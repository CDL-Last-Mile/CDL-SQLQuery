	Declare @orderTrackingId varchar(50)
	--set @orderTrackingId=1.060623
	--set @orderTrackingId=14.052523
	--set @orderTrackingId=3.050423
	--set @orderTrackingId=5.120722
	--set @orderTrackingId=5.020923 
	--set @orderTrackingId=6.020923 
	--set @orderTrackingId=7.020923 

	--set @orderTrackingId=9.020923 
	--set @orderTrackingId=12.021023
	--set @orderTrackingId=1.060623
	--set @orderTrackingId=15.053123 -- label has been created 
	--set @orderTrackingId=19.031023
	--set @orderTrackingId=1.060723 --Delivery but is exceptions with delivery before open order
	--set @orderTrackingId=8.020923 --- it is mess
	--set @orderTrackingId=7.061923 -- Full setup
	--set @orderTrackingId=1.062123
	set @orderTrackingId=1.062223
	set @orderTrackingId=2.030923

select aTimeStamp, * from XceleratorTest.dbo.xView_OrderScans where OrderTrackingID=@orderTrackingId

select * from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId
--select isAgent,* from XceleratorTest.dbo.Employees where id=4296

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
		--(select Top(1) Code2 from #tempException order by aTimeStamp DESC) as 'Exception',
		--(select Top(1) Details from #tempException order by aTimeStamp DESC) as 'ExceptionDetails',
		--(select top(1) CONCAT(FirstName, ' ', LastName) from XceleratorTest.dbo.xview_OrderDrivers od
		--left join XceleratorTest.dbo.Employees e
		--on e.id=od.DriverID
		--where od.OrderTrackingID=vo.ordertrackingid) AS 'DriverName',
		oeg.Lat,
		oeg.long,
		vo.DCity,
		vo.DState,
		vo.DZip,
		vo.DStreet,
		xvos.aTimeStamp as aTimestamp,
		--(select Top(1) SuppressOnCompletion from #tempException order by aTimeStamp DESC) as SuppressOnCompletion,
		e.isAgent as isAgent
		 --into #tempTable2
		from XceleratorTest.dbo.xView_Orders vo
	LEFT OUTER JOIN XceleratorTest.dbo.OrderPackages op 
		on op.OrderTrackingID=vo.OrderTrackingID
	LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
		ON opi.OrderTrackingID = vo.OrderTrackingID 
	left outer join XceleratorTest.dbo.xView_OrderScans xvos 
	on xvos.OrderTrackingID=@orderTrackingId and xvos.SCANlocation='L'
	LEFT OUTER join XceleratorTest.dbo.xView_EventMonitorLog_AllOrders emlao 
		on emlao.OrderTrackingID=vo.OrderTrackingID
	and emlao.EventID in(1007,2011)
	LEFT OUTER join XceleratorTest.dbo.Employees e 
		on e.id=emlao.UserID
	LEFT OUTER join XceleratorTest.dbo.terminals t
		ON t.TerminalID = vo.TerminalID
	INNER JOIN (select Top(1) * from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId ) oeg on oeg.OrderTrackingID = vo.OrderTrackingID 
	where vo.OrderTrackingID=@orderTrackingId  and ((e.isAgent=0 and emlao.EventID=1007) or (e.isAgent=1 and emlao.EventID=2011) )
		order by vo.OrderTrackingID 
--select *from #tempException


--select DISTINCT OrderTrackingID,ReferenceNumber,ShipmentCreated,TrackingEvents,DeliveryComplete,PODname,City,State,VPOD,Exception,ExceptionDetails,DriverName,DCity,DState,DZip,DStreet,aTimeStamp,lat,Long, SuppressOnCompletion
--from #tempTable2 where TrackingEvents='Driver en-route to delivery'
--Drop Table #tempTable2









--select * from XceleratorTest.dbo.eventmonitorlog 

--12223215556564546545
--select * from XceleratorTest.dbo.Employees where FirstName like 'Dominik'
--select* from XceleratorTest.dbo.xview_eventmonitorlog_allorders where OrderTrackingID=@orderTrackingId

select *from XceleratorTest.dbo.xView_OrderScans  where OrderTrackingID=@orderTrackingId
select * from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId
--drop Table #tempException
--	select ssc.Code2, ssc.Details, ossc.aTimeStamp, ssc.SuppressOnCompletion into #tempException from XceleratorTest.dbo.xView_OrderShipmentStatusCodes ossc
--left join XceleratorTest.dbo.ShipmentStatusCodes ssc on ssc.ShipmentStatusCodeID=ossc.ShipmentStatusCodeID
--where ossc.OrderTrackingID= @orderTrackingId and ossc.PackageItemID is not null



--SELECT
--	--newid() AS ID,
--	vo.OrderTrackingID,
--			   opi.RefNo as 'ReferenceNumber',
--			   vo.oDate AS 'ShipmentCreated',
--			   'Package Scanned At Delivery' AS TrackingEvents,
--			   null as 'DeliveryComplete',
--			   vo.PODname,
--			   vo.DCity as City,
--			   vo.DState as State,
--			   null as 'VPOD',
--			   (select Top(1) Code2 from #tempException order by aTimeStamp DESC) as 'Exception',
--			   (select Top(1) Details from #tempException order by aTimeStamp DESC) as 'ExceptionDetails',
--			   CONCAT(e.FirstName, ' ', e.LastName) AS 'DriverName',
--				oeg.Lat,
--			   oeg.long,
--			   vo.DCity,
--			   vo.DState,
--			   vo.DZip,
--			   vo.DStreet,
			   
--			   vos.aTimeStamp as aTimeStamp,
--			   (select Top(1) SuppressOnCompletion from #tempException order by aTimeStamp DESC) as SuppressOnCompletion
			
--		FROM XceleratorTest.dbo.xView_Orders vo
--			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID 
--			JOIN XceleratorTest.dbo.xView_OrderScans vos
--				ON vos.PackageItemID = opi.PackageItemID AND vos.SCANlocation='D'
--			--LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--			--	ON vosc.PackageItemID = opi.PackageItemID
--			--LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--			--	ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
--				ON od.OrderTrackingID = vo.OrderTrackingID
--			LEFT OUTER join XceleratorTest.dbo.Documents d 
--				ON d.DocumentID = od.DocumentID
--			INNER JOIN (select Top(1)* from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId ) oeg
--			on oeg.OrderTrackingID = vo.OrderTrackingID --and ( EventID in(2013))
--			left outer join (select Top(1) * from XceleratorTest.dbo.xview_eventmonitorlog_allorders xvemlao
--			where xvemlao.OrderTrackingID=@orderTrackingId and xvemlao.EventID=2013) xvemlao
--			on xvemlao.OrderTrackingID=@orderTrackingId
--			INNER JOIN XceleratorTest.dbo.terminals t	ON t.TerminalID = vo.TerminalID	
				
--			LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON e.ID = opi.UserID 
			
--		WHERE vos.ordertrackingid= @orderTrackingId -- and (vos.SCANlocation = 'D') 
--		order by TrackingEvents


--select * from XceleratorTest.dbo.xView_OrderShipmentStatusCodes where ordertrackingid= @orderTrackingId
--select * from XceleratorTest.dbo.xview_eventmonitorlog_allorders xvemlao	where xvemlao.OrderTrackingID=@orderTrackingId and xvemlao.EventID=2013
--select * from XceleratorTest.dbo.OrderScans where ordertrackingid= @orderTrackingId
--SELECT
--	newid() AS ID,
--	vo.OrderTrackingID,
--			   opi.RefNo as 'ReferenceNumber',
--			   vo.oDate AS 'ShipmentCreated',
--			   'Package Scanned At Delivery' AS TrackingEvents,
--			   null as 'DeliveryComplete',
--			   vo.PODname,
--			   vo.DCity as City,
--			   vo.DState as State,
--			   null as 'VPOD',
--			  --  (select Code2 from #tempException) as 'Exception',
--			   --(select Details from #tempException) as 'ExceptionDetails',
--			   CONCAT(e.FirstName, ' ', e.LastName) AS 'DriverName',
--				oeg.Lat,
--			   oeg.long,
--			   vo.DCity,
--			   vo.DState,
--			   vo.DZip,
--			   vo.DStreet,
			  
--			   vos.aTimeStamp as aTimeStamp
--			   --(select SuppressOnCompletion from #tempException) as SuppressOnCompletion
			
--		FROM XceleratorTest.dbo.xView_Orders vo
--			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
--				ON opi.OrderTrackingID = vo.OrderTrackingID 
--			JOIN XceleratorTest.dbo.xView_OrderScans vos
--				ON vos.PackageItemID = opi.PackageItemID AND vos.SCANlocation='D'
				
--			LEFT OUTER JOIN XceleratorTest.dbo.xView_OrderShipmentStatusCodes vosc
--				ON vosc.PackageItemID = opi.PackageItemID
--			LEFT OUTER JOIN XceleratorTest.dbo.ShipmentStatusCodes ssc 
--				ON ssc.ShipmentStatusCodeID = vosc.ShipmentStatusCodeID
--			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
--				ON od.OrderTrackingID = vo.OrderTrackingID
--			LEFT OUTER join XceleratorTest.dbo.Documents d 
--				ON d.DocumentID = od.DocumentID
--			INNER JOIN (select Top(1)* from XceleratorTest.dbo.xView_OrderEventGPS where OrderTrackingID=@orderTrackingId) oeg
--			on oeg.OrderTrackingID = vo.OrderTrackingID --and ( EventID in(2013))
--			left outer join (select Top(1) * from XceleratorTest.dbo.xview_eventmonitorlog_allorders xvemlao	where xvemlao.OrderTrackingID=@orderTrackingId and xvemlao.EventID=2013) xvemlao
--			on xvemlao.PackageItemID=opi.PackageItemID 
--			and xvemlao.EventID=2013
--			INNER JOIN XceleratorTest.dbo.terminals t	
--			ON t.TerminalID = vo.TerminalID		
--			LEFT OUTER join XceleratorTest.dbo.Employees e 
--				ON e.ID = opi.UserID 	
--		WHERE vo.ordertrackingid= @orderTrackingId -- and (vos.SCANlocation = 'D') 
		--order by TrackingEvents
--select Top(1) * from XceleratorTest.dbo.xView_OrderScans WHERE ordertrackingid= @orderTrackingId and SCANlocation='d'
--select Top(1) * from XceleratorTest.dbo.xview_eventmonitorlog_allorders xvemlao	where xvemlao.OrderTrackingID=@orderTrackingId and xvemlao.EventID=2013

----select SCANlocation,aTimeStamp from xView_OrderScans where OrderTrackingID=@orderTrackingId and SCANlocation='D'
----select * from xView_EventMonitorLog_AllOrders where OrderTrackingID=@orderTrackingId and EventID=2013


----SELECT --top(1)
----	--newid() AS ID,
----	vo.OrderTrackingID,
----			   opi.RefNo as 'ReferenceNumber',
----			   vo.oDate AS 'ShipmentCreated',
----			   'Delivery complete' AS TrackingEvents,
----			   vo.PODcompletion as 'DeliveryComplete',
----			   vo.PODname,
----			   vo.DCity as City,
----			   vo.DState as State,
----			   d.DocumentBinary as 'VPOD',
----			   -- (select Code2 from #tempException) as 'Exception',
----			  -- (select Details from #tempException) as 'ExceptionDetails',
----			   --CONCAT(e.FirstName, ' ', e.LastName) AS 'DriverName',
----			   vo.DCity,
----			   vo.DState,
----			   vo.DZip,
----			   vo.DStreet,
----			   vo.PODcompletion as aTimestamp,
----			   --(select SuppressOnCompletion from #tempException) as SuppressOnCompletion,
----			   '',
----			   ''	 
----		FROM XceleratorTest.dbo.xView_Orders vo
----			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
----				ON opi.OrderTrackingID = vo.OrderTrackingID 
----			LEFT OUTER join XceleratorTest.dbo.xView_orderdocuments od 
----				ON od.OrderTrackingID = vo.OrderTrackingID
----			LEFT OUTER join XceleratorTest.dbo.Documents d 
----				ON d.DocumentID = od.DocumentID
----			left outer join XceleratorTest.dbo.xview_eventmonitorlog_allorders emlo
----			on emlo.OrderTrackingID=@orderTrackingId
----       JOIN XceleratorTest.dbo.eventmonitorevents eme
----         ON emlo.eventid = eme.eventid
----		WHERE vo.ordertrackingid= @orderTrackingId
----		and emlo.EventID=1090 and vo.PODcompletion is not null	
----		order by TrackingEvents









----select * FROM XceleratorTest.dbo.xView_Orders vo
----			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
----				ON opi.OrderTrackingID = vo.OrderTrackingID 
----			JOIN XceleratorTest.dbo.xView_OrderScans vos
----				ON vos.PackageItemID = opi.PackageItemID
			
----			where vo.OrderTrackingID=@orderTrackingId







----select * from XceleratorTest.dbo.xView_Orders vo
----			LEFT OUTER JOIN XceleratorTest.dbo.xview_orderpackageitems opi
----				ON opi.OrderTrackingID = vo.OrderTrackingID 
----			JOIN XceleratorTest.dbo.xView_OrderScans vos
----				ON vos.PackageItemID = opi.PackageItemID
----where vo.OrderTrackingID=@orderTrackingId
----select vo.PODcompletion from XceleratorTest.dbo.xView_Orders vo

----where vo.OrderTrackingID=@orderTrackingId

--select PODcompletion from XceleratorTest.dbo.xView_Orders where OrderTrackingID=@orderTrackingId

--	SELECT        emlo.ordertrackingid,
--              emlo.eventid,
--              eme.NAME,
--              emlo.userid,
--              emlo.stimestamp,
--              emlo.packageitemid,
--              emlo.shipmentstatuscodeid
--FROM   XceleratorTest.dbo.xview_eventmonitorlog_allorders emlo
--       JOIN XceleratorTest.dbo.eventmonitorevents eme
--         ON emlo.eventid = eme.eventid
--WHERE  emlo.ordertrackingid = @orderTrackingId
--order by sTimeStamp asc 



