/* =============================================================================
   Ranking de itens mais frequentes — Snowflake
   -----------------------------------------------------------------------------
   Os itens de cada campanha chegam concatenados numa única coluna de texto,
   separados por espaço. Esta rotina explode a string em linhas, apura a
   frequência de cada item e devolve o top 3 por categoria — reconsolidado em
   uma única string por meio de LISTAGG.

   Técnicas: LATERAL SPLIT_TO_TABLE, ROW_NUMBER por partição, LISTAGG com
             WITHIN GROUP, CTAS para materializar o resultado.
   ============================================================================= */

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Explode a string de itens e apura a frequência dos últimos 30 dias
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE ANALYTICS.MART.ITENS_FREQUENCIA AS
SELECT
    CAT.NOME_CATEGORIA   AS CATEGORIA,
    CAM.CODIGO_CATEGORIA,
    VALUE                AS ITEM,
    COUNT(*)             AS FREQUENCIA
FROM (
    SELECT  RES.ITENS_SORTEADOS,
            CAM.CODIGO_CATEGORIA,
            CAT.NOME_CATEGORIA
    FROM        ANALYTICS.RAW_APP.RESULTADOS_CAMPANHA RES
    INNER JOIN  ANALYTICS.RAW_APP.CAMPANHAS CAM
            ON  CAM.CODIGO_CAMPANHA = RES.CODIGO_CAMPANHA
    INNER JOIN  ANALYTICS.RAW_APP.CATEGORIAS CAT
            ON  CAM.CODIGO_CATEGORIA = CAT.CODIGO_CATEGORIA
    -- Categorias de teste ficam fora da análise
    WHERE       CAM.CODIGO_CATEGORIA NOT IN (5, 6, 7)
      AND       DATEDIFF('day', CAM.DATA_ENCERRAMENTO, CURRENT_DATE()) <= 30
) X,
LATERAL SPLIT_TO_TABLE(ITENS_SORTEADOS, ' ')
WHERE CAST(TRIM(VALUE) AS VARCHAR) NOT IN ('1','2','3','4','5','6','-')
GROUP BY CAT.NOME_CATEGORIA, CAM.CODIGO_CATEGORIA, VALUE
ORDER BY FREQUENCIA DESC, CODIGO_CATEGORIA ASC;

-- ---------------------------------------------------------------------------
-- 2. Top 3 por categoria, consolidado numa string legível
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE ANALYTICS.MART.ITENS_MAIS_FREQUENTES AS
SELECT CATEGORIA, ITENS
FROM (
    SELECT
        CODIGO_CATEGORIA,
        CATEGORIA,
        LISTAGG(ITEM, ' - ') WITHIN GROUP (ORDER BY FREQUENCIA DESC) AS ITENS
    FROM (
        SELECT
            CODIGO_CATEGORIA,
            CATEGORIA,
            ITEM,
            FREQUENCIA,
            ROW_NUMBER() OVER (PARTITION BY CATEGORIA ORDER BY FREQUENCIA DESC) AS RN
        FROM ANALYTICS.MART.ITENS_FREQUENCIA
    )
    WHERE RN <= 3
    GROUP BY CODIGO_CATEGORIA, CATEGORIA

    UNION ALL

    -- Linha agregada: item mais frequente considerando todas as categorias
    SELECT
        99,
        'GERAL',
        ITEM_TOP
    FROM (
        SELECT ITEM AS ITEM_TOP, SUM(FREQUENCIA) AS TOTAL
        FROM ANALYTICS.MART.ITENS_FREQUENCIA
        GROUP BY ITEM
        ORDER BY TOTAL DESC
        LIMIT 1
    )
);

COMMIT;
