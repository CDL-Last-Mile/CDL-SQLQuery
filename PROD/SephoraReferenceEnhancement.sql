USE [CDLData]
GO
/****** Object:  StoredProcedure [dbo].[SephoraReferenceEnhancement]    Script Date: 6/13/2023 4:00:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SephoraReferenceEnhancement]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
UPDATE Xcelerator.dbo.orders 
SET    orders.clientrefno3 = opi.refno

FROM    Xcelerator.dbo.orders o
       JOIN  Xcelerator.dbo.orderpackageitems opi
         ON o.ordertrackingid = opi.ordertrackingid
WHERE  o.status = 'N'
       AND o.clientid = 7937
       AND o.clientrefno3 = '' 
END
