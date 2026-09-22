/* =============================================================================
   Carga incremental de pedidos — Snowflake
   -----------------------------------------------------------------------------
   Stored procedure que consome arquivos JSON de um stage externo e aplica MERGE
   sobre a tabela analítica, garantindo idempotência: reexecutar a carga não
   duplica registro nem perde atualização.

   Padrão aplicado em produção para sincronizar o banco transacional com o data
   warehouse, com janela de execução diária.

   Técnicas: stage externo, parsing de JSON semiestruturado ($1:"campo"::TIPO),
             MERGE com chave composta, procedure em SQL script.
   ============================================================================= */

CREATE OR REPLACE PROCEDURE ANALYTICS.STAGING.SP_LOAD_PEDIDOS()
RETURNS INT NOT NULL
LANGUAGE SQL
AS
$$
BEGIN

    MERGE INTO ANALYTICS.STAGING.PEDIDOS AS TARGET
    USING (
        -- O stage entrega JSON bruto; a tipagem é feita na leitura para que a
        -- tabela de destino já nasça com os tipos corretos.
        SELECT
            $1:"CodigoPedido"::INTEGER       AS CODIGO_PEDIDO,
            $1:"NumeroParcela"::INTEGER      AS NUMERO_PARCELA,
            $1:"CodigoCliente"::INTEGER      AS CODIGO_CLIENTE,
            $1:"DataPedido"::TIMESTAMP_NTZ   AS DATA_PEDIDO,
            $1:"Valor"::FLOAT                AS VALOR,
            $1:"TipoCompra"::STRING          AS TIPO_COMPRA,
            $1:"Situacao"::STRING            AS SITUACAO,
            $1:"ValorProduto"::FLOAT         AS VALOR_PRODUTO,
            $1:"ValorFrete"::FLOAT           AS VALOR_FRETE,
            $1:"ValorDesconto"::FLOAT        AS VALOR_DESCONTO,
            $1:"ValorPagar"::FLOAT           AS VALOR_PAGAR,
            $1:"CodigoCupom"::STRING         AS CODIGO_CUPOM,
            $1:"Device"::STRING              AS DEVICE,
            $1:"DataConfirmacao"::TIMESTAMP_NTZ AS DATA_CONFIRMACAO,
            $1:"PontosFidelidade"::INTEGER   AS PONTOS_FIDELIDADE
        FROM @stage_landing/pedidos.json
    ) AS SOURCE
    -- Chave composta: um pedido parcelado gera uma linha por parcela.
    ON (
        SOURCE.CODIGO_PEDIDO  = TARGET.CODIGO_PEDIDO
        AND SOURCE.NUMERO_PARCELA = TARGET.NUMERO_PARCELA
    )

    WHEN MATCHED THEN
        UPDATE SET
            TARGET.CODIGO_CLIENTE    = SOURCE.CODIGO_CLIENTE,
            TARGET.DATA_PEDIDO       = SOURCE.DATA_PEDIDO,
            TARGET.VALOR             = SOURCE.VALOR,
            TARGET.TIPO_COMPRA       = SOURCE.TIPO_COMPRA,
            TARGET.SITUACAO          = SOURCE.SITUACAO,
            TARGET.VALOR_PRODUTO     = SOURCE.VALOR_PRODUTO,
            TARGET.VALOR_FRETE       = SOURCE.VALOR_FRETE,
            TARGET.VALOR_DESCONTO    = SOURCE.VALOR_DESCONTO,
            TARGET.VALOR_PAGAR       = SOURCE.VALOR_PAGAR,
            TARGET.CODIGO_CUPOM      = SOURCE.CODIGO_CUPOM,
            TARGET.DEVICE            = SOURCE.DEVICE,
            TARGET.DATA_CONFIRMACAO  = SOURCE.DATA_CONFIRMACAO,
            TARGET.PONTOS_FIDELIDADE = SOURCE.PONTOS_FIDELIDADE

    WHEN NOT MATCHED THEN
        INSERT (
            CODIGO_PEDIDO, NUMERO_PARCELA, CODIGO_CLIENTE, DATA_PEDIDO, VALOR,
            TIPO_COMPRA, SITUACAO, VALOR_PRODUTO, VALOR_FRETE, VALOR_DESCONTO,
            VALOR_PAGAR, CODIGO_CUPOM, DEVICE, DATA_CONFIRMACAO, PONTOS_FIDELIDADE
        )
        VALUES (
            SOURCE.CODIGO_PEDIDO, SOURCE.NUMERO_PARCELA, SOURCE.CODIGO_CLIENTE,
            SOURCE.DATA_PEDIDO, SOURCE.VALOR, SOURCE.TIPO_COMPRA, SOURCE.SITUACAO,
            SOURCE.VALOR_PRODUTO, SOURCE.VALOR_FRETE, SOURCE.VALOR_DESCONTO,
            SOURCE.VALOR_PAGAR, SOURCE.CODIGO_CUPOM, SOURCE.DEVICE,
            SOURCE.DATA_CONFIRMACAO, SOURCE.PONTOS_FIDELIDADE
        );

    RETURN 1;

END;
$$;

-- Execução
CALL ANALYTICS.STAGING.SP_LOAD_PEDIDOS();
