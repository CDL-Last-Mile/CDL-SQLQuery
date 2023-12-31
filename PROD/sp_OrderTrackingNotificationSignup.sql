USE [Xcelerator]
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderTrackingNotificationSignup]    Script Date: 3/16/2023 2:44:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Vinay Rudra
-- Create date: 02/09/2023
-- Description:	OrderTracking Notification Signup
-- =============================================
ALTER PROCEDURE [dbo].[sp_OrderTrackingNotificationSignup]
	-- Add the parameters for the stored procedure here
	@orderTrackingId varchar(50), 
	@email varchar(100) = null,
	@phone varchar(25) = null,
	@onPod int,
	@nextStopDelivery int

AS
BEGIN

if exists (select OrderTrackingID  FROM dbo.xview_orderpackageitems where RefNo=@orderTrackingId)
begin
select  @orderTrackingId=OrderTrackingID  FROM dbo.xview_orderpackageitems where RefNo=@orderTrackingId
end
	DECLARE @result bit
	SET @result = 0

	SET NOCOUNT ON;
	--BEGIN TRY
		DECLARE @id int
		IF (@email <> '' AND @email LIKE '_%@__%.__%')
		begin
			IF NOT EXISTS(select 1 from orderautonotification where OrderTrackingID = @orderTrackingId)	
				BEGIN			
					insert into orderautonotification (OrderTrackingID, OnPOD, OnNextStopDelivery, Email, OnSubmittal, OnPickup, OnDelivery, OnSubmittal_Sent, OnPickup_Sent, OnDelivery_Sent, OnPOD_Sent, Category, OnNextStopPickup, OnNextStopPickup_Sent, OnNextStopDelivery_Sent, OnDriverAssigned, OnDriverAssigned_Sent, OnPickupProximityReached, OnPickupProximityReached_Sent, OnDeliveryProximityReached, OnDeliveryProximityReached_Sent, OnPickupETAchange, OnPickupETAchange_Sent, OnDeliveryETAchange, OnDeliveryETAchange_Sent)
					values (@orderTrackingId, @onPod, @nextStopDelivery, @email, 0, 0, 0, 0, 0, 0, 0, 'D', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
					set @result = 1			
				END
			ELSE												 
				BEGIN
					--select @id = ID from orderautonotification where OrderTrackingID = @orderTrackingId AND Email = @email
					Update OrderAutoNotification set Email = @email, OnPOD = @onPod, OnNextStopDelivery = @nextStopDelivery, Category = 'D' where OrderTrackingID = @orderTrackingId AND Email = @email
					set @result = 1
				ENd
		end
		IF @phone <> '' AND @phone IS NOT NULL
			IF (NOT EXISTS(select 1 from orderautonotification where OrderTrackingID = @orderTrackingId AND Phone = @phone))
				BEGIN
					insert into orderautonotification (OrderTrackingID, OnPOD, OnNextStopDelivery, Phone, OnSubmittal, OnPickup, OnDelivery, OnSubmittal_Sent, OnPickup_Sent, OnDelivery_Sent, OnPOD_Sent, Category, OnNextStopPickup, OnNextStopPickup_Sent, OnNextStopDelivery_Sent, OnDriverAssigned, OnDriverAssigned_Sent, OnPickupProximityReached, OnPickupProximityReached_Sent, OnDeliveryProximityReached, OnDeliveryProximityReached_Sent, OnPickupETAchange, OnPickupETAchange_Sent, OnDeliveryETAchange, OnDeliveryETAchange_Sent)
					values (@orderTrackingId, @onPod, @nextStopDelivery, @phone, 0, 0, 0, 0, 0, 0, 0, 'D', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
					set @result = 1
				END
			ELSE					
				BEGIN
					select @id = ID from orderautonotification where OrderTrackingID = @orderTrackingId AND Phone = @phone
					Update OrderAutoNotification set Phone = @phone, OnPOD = @onPod, OnNextStopDelivery = @nextStopDelivery, Category = 'D' where OrderTrackingID = @orderTrackingId AND ID = @id
					set @result = 1
				END
		select @result as Id
	--END TRY
	--BEGIN CATCH
	--	SELECT @result as Id
	--END CATCH
END
