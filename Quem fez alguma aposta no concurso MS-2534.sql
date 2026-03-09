SubscriberKey (Usuarios > CodigoUsuario)
eMail (Usuarios > Email)
PrimeiroNome (Usuarios > Nome > Tem uma fórmula para fazer)
Qtd FSJ (Qtde de FSJ deste concurso)
Qtd BOLÕES (Qtde de Bolões deste concurso)
SaldoTotal (Usuarios > SaldoTotal)
ValorInvestidoNoConcurso (Cotas * ValorCota)
Locale (Sempre "BR")
Phone (Usuarios > TelefoneCelular)
Obs. Phone padrão 5511222223333

Filtros:
Quem fez alguma aposta no concurso MS-2534. (puxar o nosso CodigoConcurso interno)
Devem ser apostas cujos pedidos foram confirmados, Situacao = 'C'.
O ValorInvestidoNoConcurso deve ser maior ou igual a 1.







select A.CodigoUsuario, A.PrimeiroNome, A.Email, A.Celular, B.Locale,A.QtdePedidosFSJ, a.TotalFSj, B.QtdePedidosBolao, B.TotalBolao, A.SaldoTotal
	from (
SELECT
	U.CodigoUsuario,
	isnull(u.Nome,'') as Nome, 
			case 
				when((u.Nome = '') or (u.nome is null)) then ''
				when(charindex(' ',RTRIM(LTRIM(u.Nome)),1) = 0) then concat(UPPER(substring(u.Nome,1,1)),lower(substring(RTRIM(LTRIM(u.Nome)),2,len(RTRIM(LTRIM(u.Nome)))-1))) 
				else concat(UPPER(substring(u.Nome,1,1)),lower(substring(RTRIM(LTRIM(u.Nome)),2,(charindex(' ',RTRIM(LTRIM(u.Nome)),1)-2)))) 
			end PrimeiroNome, 
	U.Email,
	ISNULL(U.TelefoneCelular, 'Não informado') AS Celular,
	COUNT(p.Valor) AS QtdePedidosFSJ,
	SUM(PG.Cotas*G.ValorCota) AS TotalFSJ,
	U.SaldoTotal
FROM sorteonline.dbo.Usuarios U (nolock)
JOIN sorteonline.dbo.Pagamentos P (nolock)
    ON U.CodigoUsuario = P.CodigoUsuario
JOIN sorteonline.dbo.ParticipacoesGruposConcursos PG (nolock)
    ON P.CodigoPagamento = PG.CodigoPagamento 

JOIN sorteonline.dbo.Grupos G (nolock)
    ON PG.CodigoGrupo = G.CodigoGrupo
WHERE P.TipoCompra IN ('CT', 'LS')
AND P.Situacao = 'C' 
AND PG.CodigoConcurso = '30348'
AND P.Valor >= 1

and G.origem = 'C'

group BY U.CodigoUsuario, ISNULL(U.TelefoneCelular, 'Não informado'), U.Email, U.SaldoTotal, U.Nome
--ORDER BY U.CodigoUsuario, U.Email, U.Nome
) A
join (
SELECT
	U.CodigoUsuario,
	isnull(u.Nome,'') as Nome, 
			case 
				when((u.Nome = '') or (u.nome is null)) then ''
				when(charindex(' ',RTRIM(LTRIM(u.Nome)),1) = 0) then concat(UPPER(substring(u.Nome,1,1)),lower(substring(RTRIM(LTRIM(u.Nome)),2,len(RTRIM(LTRIM(u.Nome)))-1))) 
				else concat(UPPER(substring(u.Nome,1,1)),lower(substring(RTRIM(LTRIM(u.Nome)),2,(charindex(' ',RTRIM(LTRIM(u.Nome)),1)-2)))) 
			end PrimeiroNome, 
	U.Email,
	ISNULL(U.TelefoneCelular, 'Não informado') AS Celular,
	SG.Locale AS Locale,
	COUNT(p.Valor) AS QtdePedidosBolao,
	SUM(PG.Cotas*G.ValorCota) AS TotalBolao,
	U.SaldoTotal
FROM  dl_mktcloudsf.dbo.SegmentacaoGeral SG  (nolock)
JOIN sorteonline.dbo.Usuarios U (nolock)
    ON SG.CodigoUsuario = U.CodigoUsuario
JOIN sorteonline.dbo.Pagamentos P (nolock)
    ON U.CodigoUsuario = P.CodigoUsuario
JOIN sorteonline.dbo.ParticipacoesGruposConcursos PG (nolock)
    ON P.CodigoPagamento = PG.CodigoPagamento 

JOIN sorteonline.dbo.Grupos G (nolock)
    ON PG.CodigoGrupo = G.CodigoGrupo
WHERE P.TipoCompra IN ('CT', 'LS')
AND P.Situacao = 'C' 
AND PG.CodigoConcurso = '30348'
AND P.Valor >= 1
and G.origem in ('L','S')

group BY U.CodigoUsuario, ISNULL(U.TelefoneCelular, 'Não informado'), U.Email, U.SaldoTotal, U.Nome, SG.Locale

 
) B on A.CodigoUsuario = B.CodigoUsuario

ORDER BY A.CodigoUsuario
