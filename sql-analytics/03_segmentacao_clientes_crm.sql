/* =============================================================================
   Base de segmentação de clientes para CRM — SQL Server
   -----------------------------------------------------------------------------
   Monta a base que alimenta a ferramenta de automação de marketing: identificação
   do cliente, métricas de comportamento de compra e status de elegibilidade para
   comunicação.

   O status é calculado por precedência: opt-out e bloqueios têm prioridade sobre
   qualquer classificação de atividade — enviar comunicação a quem pediu descadastro
   é erro grave, então a regra é avaliada primeiro.

   Técnicas: normalização de nome com CHARINDEX/SUBSTRING, subconsultas correlatas
             para ticket médio e recência, CASE com precedência de regras.
   ============================================================================= */

SELECT
    SubscriberKey,
    PrimeiroNome,
    Email,
    Locale,
    Phone,
    UltimaCompra,
    SaldoTotal,
    SegmentoEspecial,
    TicketMedioGeral,
    Status
FROM (

    SELECT
        P.CODIGO_CLIENTE AS SubscriberKey,

        -- Extrai e normaliza o primeiro nome: capitaliza a inicial e coloca o
        -- restante em minúsculas. Trata nome vazio e nome sem sobrenome.
        (CASE
            WHEN ((C.NOME = '') OR (C.NOME IS NULL))
                THEN ''
            WHEN (CHARINDEX(' ', RTRIM(LTRIM(C.NOME)), 1) = 0)
                THEN CONCAT(
                        UPPER(SUBSTRING(C.NOME, 1, 1)),
                        LOWER(SUBSTRING(RTRIM(LTRIM(C.NOME)), 2, LEN(RTRIM(LTRIM(C.NOME))) - 1))
                     )
            ELSE CONCAT(
                        UPPER(SUBSTRING(C.NOME, 1, 1)),
                        LOWER(SUBSTRING(RTRIM(LTRIM(C.NOME)), 2, (CHARINDEX(' ', RTRIM(LTRIM(C.NOME)), 1) - 2)))
                 )
        END) AS PrimeiroNome,

        C.EMAIL AS Email,
        'BR'    AS Locale,

        -- Telefone no formato E.164 exigido pela plataforma de disparo
        (CASE
            WHEN (C.TELEFONE_CELULAR IS NULL) THEN ''
            WHEN (REPLACE(C.TELEFONE_CELULAR, ' ', '') = '') THEN ''
            ELSE CONCAT('55', REPLACE(C.TELEFONE_CELULAR, ' ', ''))
        END) AS Phone,

        ULT.ULTIMA_DATA AS UltimaCompra,
        CAST(C.SALDO_TOTAL AS DECIMAL(18,2)) AS SaldoTotal,
        CAST(TKT.MEDIO AS DECIMAL(18,2))     AS TicketMedioGeral,

        -- Precedência: descadastro e bloqueios sobrepõem status de atividade
        (CASE
            WHEN (C.RECEBER_EMAILS = 'N') THEN 'Opt-Out'
            WHEN (C.BLACKLIST = 'S')      THEN 'Blacklist'
            WHEN (C.BLOQUEADO = 'S')      THEN 'Bloqueado'
            WHEN (ATV.CODIGO_CLIENTE IS NULL) THEN 'Inativo'
            ELSE 'Ativo'
        END) AS Status,

        SEG.SEGMENTO_ESPECIAL AS SegmentoEspecial

    FROM ANALYTICS.RAW_APP.CLIENTES C

    JOIN ANALYTICS.CRM.SEGMENTOS_ESPECIAIS SEG
        ON C.CODIGO_CLIENTE = SEG.SUBSCRIBER_KEY

    JOIN ANALYTICS.RAW_APP.PEDIDOS P
        ON C.CODIGO_CLIENTE = P.CODIGO_CLIENTE

    JOIN ANALYTICS.RAW_APP.ITENS_PEDIDO IP
        ON  P.CODIGO_PEDIDO  = IP.CODIGO_PEDIDO
        AND P.NUMERO_PARCELA = IP.NUMERO_PARCELA

    JOIN ANALYTICS.RAW_APP.LOTES L
        ON IP.CODIGO_LOTE = L.CODIGO_LOTE

    -- Ticket médio considerando apenas pedidos confirmados de valor relevante
    LEFT JOIN (
        SELECT
            P.CODIGO_CLIENTE,
            (SUM(P.VALOR) / COUNT(*)) AS MEDIO
        FROM ANALYTICS.RAW_APP.PEDIDOS P
        WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
          AND P.SITUACAO = 'CONFIRMADO'
          AND P.VALOR >= 1
        GROUP BY P.CODIGO_CLIENTE
    ) TKT
        ON C.CODIGO_CLIENTE = TKT.CODIGO_CLIENTE

    -- Data da última compra efetiva
    LEFT JOIN (
        SELECT
            P.CODIGO_CLIENTE,
            MAX(P.DATA_PEDIDO) AS ULTIMA_DATA
        FROM ANALYTICS.RAW_APP.PEDIDOS P
        JOIN ANALYTICS.RAW_APP.ITENS_PEDIDO IP
            ON  P.CODIGO_PEDIDO  = IP.CODIGO_PEDIDO
            AND P.NUMERO_PARCELA = IP.NUMERO_PARCELA
        WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
          AND P.SITUACAO = 'CONFIRMADO'
          AND P.VALOR >= 1
        GROUP BY P.CODIGO_CLIENTE
    ) ULT
        ON C.CODIGO_CLIENTE = ULT.CODIGO_CLIENTE

    -- Flag de atividade: comprou nos últimos 120 dias
    LEFT JOIN (
        SELECT DISTINCT P.CODIGO_CLIENTE
        FROM ANALYTICS.RAW_APP.PEDIDOS P
        WHERE P.TIPO_COMPRA <> 'CREDITO'
          AND P.SITUACAO = 'CONFIRMADO'
          AND P.VALOR >= 1
          AND CAST(P.DATA_PEDIDO AS DATE) >= DATEADD(DAY, -120, CAST(GETDATE() AS DATE))
    ) ATV
        ON P.CODIGO_CLIENTE = ATV.CODIGO_CLIENTE

    WHERE P.TIPO_COMPRA IN ('AVULSO', 'RECORRENTE')
      AND P.SITUACAO = 'CONFIRMADO'
      AND P.VALOR >= 1

    GROUP BY
        P.CODIGO_CLIENTE, C.NOME, C.EMAIL, C.TELEFONE_CELULAR, ULT.ULTIMA_DATA,
        C.SALDO_TOTAL, TKT.MEDIO, C.RECEBER_EMAILS, C.BLACKLIST, C.BLOQUEADO,
        ATV.CODIGO_CLIENTE, SEG.SEGMENTO_ESPECIAL

) BASE;
