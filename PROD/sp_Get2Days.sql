USE [CDLData]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get2Days]    Script Date: 6/29/2023 10:43:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get2Days](
	@clientID int)
AS
BEGIN

	SET NOCOUNT ON;

SELECT CONVERT(DATE, o.odate) AS 'ManifestDate',
       o.ordertrackingid,
       o.clientrefno,
       opi.refno              AS 'Barcode',
       dconame,
       dcontact,
       dstreet,
       dcity,
       dstate,
       dzip
FROM   Xcelerator.dbo.orders o
       JOIN Xcelerator.dbo.orderpackageitems opi
         ON o.ordertrackingid = opi.ordertrackingid
WHERE  clientid = @clientID
       AND o.status = 'N'
       AND o.odate <= CONVERT(DATE, Getdate() - 2)
       AND o.ordertrackingid NOT IN (SELECT ordertrackingid
                                     FROM   Xcelerator.dbo.orderscans)
ORDER  BY o.odate ASC 

END
