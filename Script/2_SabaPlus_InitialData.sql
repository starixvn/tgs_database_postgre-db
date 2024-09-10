/*
	Louisa: Initial data
	2024-09-10
*/

--------------------------------
--dbo.SystemSetting 
--------------------------------
--- definition for ServiceName

INSERT INTO dbo.SystemSetting ( KeyName,KeyValue)
VALUES   ('SabaPlus_PlaceBet'			, '1' )
		,('SabaPlus_EndGame'			, '2' )
		,('SabaPlus_PlaceBetAndSettle'	, '3' )
		,('SabaPlus_FreeSpin'			, '4' )
		,('SabaPlus_Bonus'				, '5' )
		,('SabaPlus_BetResultCheck'		, '6' )
		,('SabaPlus_VoidGame'			, '7' )
			