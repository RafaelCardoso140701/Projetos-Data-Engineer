

select a.ano, a.mes, a.TotalFSj, B.TotalBolao
	from (
SELECT
	year(P.data) as ano,
	month(P.data) as mes,
    SUM(PG.Cotas*G.ValorCota) AS TotalFSJ
FROM sorteonline.dbo.Usuarios U (nolock)
JOIN sorteonline.dbo.Pagamentos P (nolock)
    ON U.CodigoUsuario = P.CodigoUsuario
JOIN sorteonline.dbo.ParticipacoesGruposConcursos PG (nolock)
    ON P.CodigoPagamento = PG.CodigoPagamento 
    AND P.NumeroParcela = PG.NumeroParcela
JOIN sorteonline.dbo.Concursos C (nolock)
    ON PG.CodigoConcurso = C.CodigoConcurso
JOIN sorteonline.dbo.Grupos G (nolock)
    ON PG.CodigoGrupo = G.CodigoGrupo
WHERE P.TipoCompra IN ('CT', 'LS')
AND P.Situacao = 'C' 
AND P.Valor >= 1
AND DATEDIFF(MONTH, Data, GETDATE()) <= 24
AND C.Especial = 'S'
and G.origem = 'C'

group BY year(P.data), month(P.data)
) A
join (
SELECT
	year(P.data) as ano,
	month(P.data) as mes,
    SUM(PG.Cotas*G.ValorCota) AS TotalBolao
FROM sorteonline.dbo.Usuarios U (nolock)
JOIN sorteonline.dbo.Pagamentos P (nolock)
    ON U.CodigoUsuario = P.CodigoUsuario
JOIN sorteonline.dbo.ParticipacoesGruposConcursos PG (nolock)
    ON P.CodigoPagamento = PG.CodigoPagamento 
    AND P.NumeroParcela = PG.NumeroParcela
JOIN sorteonline.dbo.Concursos C (nolock)
    ON PG.CodigoConcurso = C.CodigoConcurso
JOIN sorteonline.dbo.Grupos G (nolock)
    ON PG.CodigoGrupo = G.CodigoGrupo
WHERE P.TipoCompra IN ('CT', 'LS')
AND P.Situacao = 'C' 
AND P.Valor >= 1
AND DATEDIFF(MONTH, Data, GETDATE()) <= 24
AND C.Especial = 'S'
and G.origem in ('L','S') 

group BY year(P.data), month(P.data)

) B ON A.ano = B.ano and A.mes = B.mes

order by A.ano, A.mes

