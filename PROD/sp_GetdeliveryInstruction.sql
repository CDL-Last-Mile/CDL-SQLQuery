USE [Xcelerator]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetdeliveryInstruction]    Script Date: 3/16/2023 2:43:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_GetdeliveryInstruction]
@orderTrackingId varchar(255),
@instruction varchar (255)

AS
BEGIN

if exists (select OrderTrackingID  FROM xview_orderpackageitems where RefNo=@orderTrackingId)
begin
select  @orderTrackingId=OrderTrackingID  FROM xview_orderpackageitems where RefNo=@orderTrackingId
end

DECLARE @result bit
	SET @result = 0
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE Orders set dspecinstr = @instruction from Orders o where OrderTrackingID = @orderTrackingId
	set @result = 1
END
select @result
