/* =============================================================================
   Participantes de uma campanha, por modalidade — SQL Server
   -----------------------------------------------------------------------------
   Lista os clientes que participaram de uma campanha específica, separando o
   investimento entre as duas modalidades de compra (individual e coletiva) e
   consolidando ambas numa linha por cliente.

   Saída destinada a disparo segmentado: identificação, contato, quantidade de
   pedidos e valor investido em cada modalidade.

   Regras aplicadas:
     - apenas pedidos confirmados
     - valor investido maior ou igual a 1
     - modalidade determinada pela origem do lote

   Técnicas: subconsultas agregadas por modalidade unidas por JOIN, cálculo de
             investimento como quantidade x valor unitário, tratamento de nulos.
   ============================================================================= */

DECLARE @CodigoCampanha INT = 30348;

SELECT
    IND.CODIGO_CLIENTE,
    IND.PrimeiroNome,
    IND.Email,
    IND.Celular,
    COL.Locale,
    IND.QtdePedidosIndividual,
    IND.TotalIndividual,
    COL.QtdePedidosColetivo,
    COL.TotalColetivo,
    IND.SaldoTotal
FROM (

    -- Modalidade individual
    SELECT
        C.CODIGO_CLIENTE,
        ISNULL(C.NOME, '') AS Nome,
        CASE
            WHEN ((C.NOME = '') OR (C.NOME IS NULL))
                THEN ''
            WHEN (CHARINDEX(' ', RTRIM(LTRIM(C.NOME)), 1) = 0)
                THEN CONCAT(UPPER(SUBSTRING(C.NOME, 1, 1)),
                            LOWER(SUBSTRING(RTRIM(LTRIM(C.NOME)), 2, LEN(RTRIM(LTRIM(C.NOME))) - 1)))
            ELSE CONCAT(UPPER(SUBSTRING(C.NOME, 1, 1)),
                        LOWER(SUBSTRING(RTRIM(LTRIM(C.NOME)), 2, (CHARINDEX(' ', RTRIM(LTRIM(C.NOME)), 1) - 2))))
        END AS PrimeiroNome,
        C.EMAIL,
        ISNULL(C.TELEFONE_CELULAR, 'Nao informado') AS Celular,
        COUNT(P.VALOR)                          AS QtdePedidosIndividual,
        SUM(IP.QUANTIDADE * L.VALOR_UNITARIO)   AS TotalIndividual,
        C.SALDO_TOTAL
    FROM ECOMMERCE.dbo.CLIENTES C WITH (NOLOCK)
    JOIN ECOMMERCE.dbo.PEDIDOS P WITH (NOLOCK)
        ON C.CODIGO_CLIENTE = P.CODIGO_CLIENTE
    JOIN ECOMMERCE.dbo.ITENS_PEDIDO IP WITH (NOLOCK)
        ON P.CODIGO_PEDIDO = IP.CODIGO_PEDIDO
    JOIN ECOMMERCE.dbo.LOTES L WITH (NOLOCK)
        ON IP.CODIGO_LOTE = L.CODIGO_LOTE
    WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
      AND P.SITUACAO = 'CONFIRMADO'
      AND IP.CODIGO_CAMPANHA = @CodigoCampanha
      AND P.VALOR >= 1
      AND L.ORIGEM = 'INDIVIDUAL'
    GROUP BY
        C.CODIGO_CLIENTE, ISNULL(C.TELEFONE_CELULAR, 'Nao informado'),
        C.EMAIL, C.SALDO_TOTAL, C.NOME

) IND

JOIN (

    -- Modalidade coletiva
    SELECT
        C.CODIGO_CLIENTE,
        SEG.LOCALE AS Locale,
        COUNT(P.VALOR)                          AS QtdePedidosColetivo,
        SUM(IP.QUANTIDADE * L.VALOR_UNITARIO)   AS TotalColetivo
    FROM MKT_CLOUD.dbo.SEGMENTACAO_GERAL SEG WITH (NOLOCK)
    JOIN ECOMMERCE.dbo.CLIENTES C WITH (NOLOCK)
        ON SEG.CODIGO_CLIENTE = C.CODIGO_CLIENTE
    JOIN ECOMMERCE.dbo.PEDIDOS P WITH (NOLOCK)
        ON C.CODIGO_CLIENTE = P.CODIGO_CLIENTE
    JOIN ECOMMERCE.dbo.ITENS_PEDIDO IP WITH (NOLOCK)
        ON P.CODIGO_PEDIDO = IP.CODIGO_PEDIDO
    JOIN ECOMMERCE.dbo.LOTES L WITH (NOLOCK)
        ON IP.CODIGO_LOTE = L.CODIGO_LOTE
    WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
      AND P.SITUACAO = 'CONFIRMADO'
      AND IP.CODIGO_CAMPANHA = @CodigoCampanha
      AND P.VALOR >= 1
      AND L.ORIGEM IN ('GRUPO', 'SINDICATO')
    GROUP BY C.CODIGO_CLIENTE, SEG.LOCALE

) COL
    ON IND.CODIGO_CLIENTE = COL.CODIGO_CLIENTE

ORDER BY IND.CODIGO_CLIENTE;
