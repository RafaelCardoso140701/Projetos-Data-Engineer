/* =============================================================================
   Receita mensal por modalidade, últimos 24 meses — SQL Server
   -----------------------------------------------------------------------------
   Série temporal comparando o volume investido nas duas modalidades de compra
   ao longo dos últimos 24 meses, restrita às campanhas classificadas como
   especiais.

   Usada para avaliar o peso relativo de cada modalidade em campanhas de maior
   apelo e orientar a alocação de investimento em mídia.

   Técnicas: agregação por ano/mês, janela móvel com DATEDIFF, JOIN entre
             agregados para comparação lado a lado.
   ============================================================================= */

SELECT
    IND.ANO,
    IND.MES,
    IND.TotalIndividual,
    COL.TotalColetivo
FROM (

    SELECT
        YEAR(P.DATA_PEDIDO)  AS ANO,
        MONTH(P.DATA_PEDIDO) AS MES,
        SUM(IP.QUANTIDADE * L.VALOR_UNITARIO) AS TotalIndividual
    FROM ECOMMERCE.dbo.CLIENTES C WITH (NOLOCK)
    JOIN ECOMMERCE.dbo.PEDIDOS P WITH (NOLOCK)
        ON C.CODIGO_CLIENTE = P.CODIGO_CLIENTE
    JOIN ECOMMERCE.dbo.ITENS_PEDIDO IP WITH (NOLOCK)
        ON  P.CODIGO_PEDIDO  = IP.CODIGO_PEDIDO
        AND P.NUMERO_PARCELA = IP.NUMERO_PARCELA
    JOIN ECOMMERCE.dbo.CAMPANHAS CAM WITH (NOLOCK)
        ON IP.CODIGO_CAMPANHA = CAM.CODIGO_CAMPANHA
    JOIN ECOMMERCE.dbo.LOTES L WITH (NOLOCK)
        ON IP.CODIGO_LOTE = L.CODIGO_LOTE
    WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
      AND P.SITUACAO = 'CONFIRMADO'
      AND P.VALOR >= 1
      AND DATEDIFF(MONTH, P.DATA_PEDIDO, GETDATE()) <= 24
      AND CAM.ESPECIAL = 'S'
      AND L.ORIGEM = 'INDIVIDUAL'
    GROUP BY YEAR(P.DATA_PEDIDO), MONTH(P.DATA_PEDIDO)

) IND

JOIN (

    SELECT
        YEAR(P.DATA_PEDIDO)  AS ANO,
        MONTH(P.DATA_PEDIDO) AS MES,
        SUM(IP.QUANTIDADE * L.VALOR_UNITARIO) AS TotalColetivo
    FROM ECOMMERCE.dbo.CLIENTES C WITH (NOLOCK)
    JOIN ECOMMERCE.dbo.PEDIDOS P WITH (NOLOCK)
        ON C.CODIGO_CLIENTE = P.CODIGO_CLIENTE
    JOIN ECOMMERCE.dbo.ITENS_PEDIDO IP WITH (NOLOCK)
        ON  P.CODIGO_PEDIDO  = IP.CODIGO_PEDIDO
        AND P.NUMERO_PARCELA = IP.NUMERO_PARCELA
    JOIN ECOMMERCE.dbo.CAMPANHAS CAM WITH (NOLOCK)
        ON IP.CODIGO_CAMPANHA = CAM.CODIGO_CAMPANHA
    JOIN ECOMMERCE.dbo.LOTES L WITH (NOLOCK)
        ON IP.CODIGO_LOTE = L.CODIGO_LOTE
    WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
      AND P.SITUACAO = 'CONFIRMADO'
      AND P.VALOR >= 1
      AND DATEDIFF(MONTH, P.DATA_PEDIDO, GETDATE()) <= 24
      AND CAM.ESPECIAL = 'S'
      AND L.ORIGEM IN ('GRUPO', 'SINDICATO')
    GROUP BY YEAR(P.DATA_PEDIDO), MONTH(P.DATA_PEDIDO)

) COL
    ON IND.ANO = COL.ANO AND IND.MES = COL.MES

ORDER BY IND.ANO, IND.MES;
