SELECT SubscriberKey, PrimeiroNome, Email, Locale, Phone, UltimaCompra, SaldoTotal, APOSTAESPECIAL, TKTMedio_Geral, Status
FROM (

	SELECT
		P.CodigoUsuario AS SubscriberKey,
		(CASE
			WHEN((u.Nome = '') or (u.Nome is null)) THEN ''
			WHEN(charindex(' ',RTRIM(LTRIM(u.Nome)),1) = 0) THEN concat(UPPER(substring(u.Nome,1,1)),lower(substring(RTRIM(LTRIM(u.Nome)),2,len(RTRIM(LTRIM(u.Nome)))-1))) 
			ELSE concat(UPPER(substring(u.Nome,1,1)),lower(substring(RTRIM(LTRIM(u.Nome)),2,(charindex(' ',RTRIM(LTRIM(u.Nome)),1)-2)))) 
		END ) AS PrimeiroNome,
		u.Email AS Email,
		'BR' AS Locale,
		(CASE 
			WHEN(u.TelefoneCelular is null) THEN '' 
			WHEN(REPLACE(u.TelefoneCelular,' ','') = '') THEN '' 
			ELSE CONCAT('55',REPLACE(u.TelefoneCelular,' ','')) 
		END) AS Phone,
		UD.UltData AS UltimaCompra,
		CAST(u.SaldoTotal AS DECIMAL(18,2)) AS SaldoTotal,
		CAST(TKT.Medio AS DECIMAL(18,2)) AS TKTMedio_Geral,
		(CASE 
			WHEN(u.ReceberEmails = 'N') THEN 'Opt-Out' 
			WHEN(u.Blacklist = 'S') THEN 'Blacklist' 
			WHEN(u.Bloqueado = 'S') THEN 'Bloqueado' 
			WHEN(p1.CodigoUsuario is null) THEN 'Inativo' 
			ELSE 'Ativo' 
		END) AS Status,
        DE.APOSTAESPECIAL
	FROM sorte.raw_sitesol.Usuarios u
   JOIN sorte.crm.dedicadas_especiais DE 
    ON U.CodigoUsuario = DE.SubscriberKey
	JOIN sorte.raw_sitesol.Pagamentos P 
		ON U.CodigoUsuario = P.CodigoUsuario
	JOIN sorte.raw_sitesol.ParticipacoesGruposConcursos PG 
		ON P.CodigoPagamento = PG.CodigoPagamento 
		AND P.NumeroParcela = PG.NumeroParcela
	JOIN sorte.raw_sitesol.Grupos G 
		ON PG.CodigoGrupo = G.CodigoGrupo
	LEFT JOIN ( select P.CodigoUsuario, (sum(P.Valor)/count(*)) as Medio
				from sorte.raw_sitesol.Pagamentos P  
				WHERE P.TipoCompra IN ('CT', 'LS')
				AND P.Situacao = 'C' 
				AND P.Valor >= 1
				GROUP BY P.CodigoUsuario
			) TKT
			ON U.CodigoUsuario = TKT.CodigoUsuario
	LEFT JOIN (SELECT P.CodigoUsuario, MAX(P.Data) AS UltData
				FROM sorte.raw_sitesol.Pagamentos P
				JOIN sorte.raw_sitesol.ParticipacoesGruposConcursos PG
					ON P.CodigoPagamento = PG.CodigoPagamento
					AND P.NumeroParcela = PG.NumeroParcela
				WHERE TipoCompra IN ('CT', 'LS')
				AND Situacao = 'C' 
				AND Valor >= 1
				GROUP BY P.CodigoUsuario
			) UD
			ON U.CodigoUsuario = UD.CodigoUsuario
	LEFT JOIN (
		SELECT DISTINCT p.CodigoUsuario 
		FROM sorte.raw_sitesol.Pagamentos p  
		WHERE p.TipoCompra <> 'CR' 
		AND p.Situacao = 'C' 
		AND p.Valor >= 1 
		AND cast(p.Data as Date) >= dateadd(day,-120,cast(GETDATE() as Date)) 
	) p1 
		on P.CodigoUsuario = p1.CodigoUsuario
  
	WHERE P.TipoCompra IN ('CT', 'LS')
	AND P.Situacao = 'C' 
	AND P.Valor >= 1
	GROUP BY P.CodigoUsuario, u.Nome, u.Email, u.TelefoneCelular, UD.UltData, u.SaldoTotal, TKT.Medio, u.ReceberEmails, u.Blacklist, u.Bloqueado, p1.CodigoUsuario,DE.APOSTAESPECIAL

	) FINAL

