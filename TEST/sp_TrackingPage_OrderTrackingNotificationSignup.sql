USE [CDLData]
GO
/****** Object:  StoredProcedure [dbo].[sp_TrackingPage_OrderTrackingNotificationSignup]    Script Date: 6/15/2023 8:38:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Vinay Rudra
-- Create date: 02/09/2023
-- Description:	OrderTracking Notification Signup
-- =============================================
ALTER PROCEDURE [dbo].[sp_TrackingPage_OrderTrackingNotificationSignup]
	-- Add the parameters for the stored procedure here
	@orderTrackingId varchar(50), 
	@email varchar(100) = null,
	@phone varchar(25) = null,
	@onPod int,
	@nextStopDelivery int

AS
BEGIN

DECLARE @id INT

IF EXISTS (SELECT ordertrackingid
           FROM   xceleratortest.dbo.xview_orderpackageitems
           WHERE  refno = @orderTrackingId)
  BEGIN
      SELECT @orderTrackingId = ordertrackingid
      FROM   xceleratortest.dbo.xview_orderpackageitems
      WHERE  refno = @orderTrackingId
  END

DECLARE @result BIT

SET @result = 0
SET nocount ON;

IF ( @email <> ''
     AND @email LIKE '_%@__%.__%' )
  BEGIN
      IF not EXISTS (SELECT 1
                    FROM   xceleratortest.dbo.orderautonotification
                    WHERE  ordertrackingid = @orderTrackingId)
        BEGIN
            INSERT INTO xceleratortest.dbo.orderautonotification
                        (ordertrackingid,
                         onpod,
                         onnextstopdelivery,
                         email,
                         onsubmittal,
                         onpickup,
                         ondelivery,
                         onsubmittal_sent,
                         onpickup_sent,
                         ondelivery_sent,
                         onpod_sent,
                         category,
                         onnextstoppickup,
                         onnextstoppickup_sent,
                         onnextstopdelivery_sent,
                         ondriverassigned,
                         ondriverassigned_sent,
                         onpickupproximityreached,
                         onpickupproximityreached_sent,
                         ondeliveryproximityreached,
                         ondeliveryproximityreached_sent,
                         onpickupetachange,
                         onpickupetachange_sent,
                         ondeliveryetachange,
                         ondeliveryetachange_sent)
            output      @orderTrackingId,
                        4299,
                        2,
                        1,
                        Getdate(),
                        'Email',
                        'changed from [] to ['
                        + CONVERT(NVARCHAR(50), inserted.email)
                        + '] by User: 4299',
                        NULL,
                        0
            INTO xceleratortest.dbo.orderchangelog
            VALUES      (@orderTrackingId,
                         @onPod,
                         @nextStopDelivery,
                         @email,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         'D',
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0)

            SET @result = 1
        END
      ELSE
        BEGIN
            SELECT @id = id
            FROM   xceleratortest.dbo.orderautonotification
            WHERE  ordertrackingid = @orderTrackingId and Phone is null
                   --AND email = @email

            UPDATE xceleratortest.dbo.orderautonotification
            SET    email = @email,
                   onpod = @onPod,
                   onnextstopdelivery = @nextStopDelivery,
                   category = 'D'
            output @orderTrackingId,
                   4299,
                   2,
                   1,
                   Getdate(),
                   'Email',
                   'changed from ['
                   + CONVERT(NVARCHAR(50), deleted.email)
                   + '] to ['
                   + CONVERT(NVARCHAR(50), inserted.email)
                   + '] by User: 4299',
                   NULL,
                   0
            INTO xceleratortest.dbo.orderchangelog
            WHERE  ordertrackingid = @orderTrackingId
                   AND id = @id

            --SET @result = 1
        END
  END

IF (@phone <> ''
   AND @phone IS NOT NULL)
   begin
   
  IF  NOT EXISTS(SELECT 1
                  FROM   xceleratortest.dbo.orderautonotification
                  WHERE  ordertrackingid = @orderTrackingId and Phone is not null
                        ) 
    BEGIN
	
        INSERT INTO xceleratortest.dbo.orderautonotification
                    (ordertrackingid,
                     onpod,
                     onnextstopdelivery,
                     phone,
                     onsubmittal,
                     onpickup,
                     ondelivery,
                     onsubmittal_sent,
                     onpickup_sent,
                     ondelivery_sent,
                     onpod_sent,
                     category,
                     onnextstoppickup,
                     onnextstoppickup_sent,
                     onnextstopdelivery_sent,
                     ondriverassigned,
                     ondriverassigned_sent,
                     onpickupproximityreached,
                     onpickupproximityreached_sent,
                     ondeliveryproximityreached,
                     ondeliveryproximityreached_sent,
                     onpickupetachange,
                     onpickupetachange_sent,
                     ondeliveryetachange,
                     ondeliveryetachange_sent)
        output      @orderTrackingId,
                    4299,
                    2,
                    1,
                    Getdate(),
                    'Phone',
                    'changed from [] to ['
                    + CONVERT(NVARCHAR(50), inserted.phone)
                    + '] by User: 4299',
                    NULL,
                    0
        INTO xceleratortest.dbo.orderchangelog
        VALUES      (@orderTrackingId,
                     @onPod,
                     @nextStopDelivery,
                     @phone,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     'D',
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0)

        SET @result = 1
    END
  ELSE
    BEGIN
	 
        SELECT @id = id
        FROM   xceleratortest.dbo.orderautonotification
        WHERE  ordertrackingid = @orderTrackingId
               --AND phone = @phone
print @id
        UPDATE xceleratortest.dbo.orderautonotification
        SET    phone = @phone,
               onpod = @onPod,
               onnextstopdelivery = @nextStopDelivery,
               category = 'D'
        output @orderTrackingId,
               4299,
               2,
               1,
               Getdate(),
               'Phone',
               'changed from ['
               + CONVERT(NVARCHAR(50), deleted.phone)
               + '] to ['
               + CONVERT(NVARCHAR(50), inserted.phone)
               + '] by User: 4299',
               NULL,
               0
        INTO xceleratortest.dbo.orderchangelog
        WHERE  ordertrackingid = @orderTrackingId
               AND id = @id

        SET @result = 1
    END
END
END
SELECT @result AS Id 
