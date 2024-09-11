/*
	Louisa: Initial data
	2024-09-10
*/

--------------------------------
--dbo.SystemSetting 
--------------------------------

------Truncate table dbo.SystemSetting

------SabaPlus API name--------------------
INSERT INTO dbo.SystemSetting ( KeyName,KeyValue)
VALUES   ('SabaPlus_PlaceBet'			, '1' )
		,('SabaPlus_EndGame'			, '2' )
		,('SabaPlus_PlaceBetAndSettle'	, '3' )
		,('SabaPlus_FreeSpin'			, '4' )
		,('SabaPlus_Bonus'				, '5' )
		,('SabaPlus_BetResultCheck'		, '6' )
		,('SabaPlus_VoidGame'			, '7' )

------TicketStatus--------------------
INSERT INTO dbo.SystemSetting ( KeyName,KeyValue)
VALUES   ('TicketStatus_Running'		,'0' )
		,('TicketStatus_Won'			,'1' )
		,('TicketStatus_Lose' 			,'2' )
		,('TicketStatus_Draw' 			,'3' )
		,('TicketStatus_Void'			,'4' )
		,('TicketStatus_Reject'			,'5' )
		,('TicketStatus_Refund' 		,'6' )
		