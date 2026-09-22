# Projetos de Engenharia de Dados

Coletânea de trabalhos em SQL analítico, automação e coleta de dados.

`Snowflake` `SQL Server` `Python` `pandas` `BeautifulSoup` `Flask`

---

## SQL Analítico

Consultas e rotinas que reproduzem padrões que apliquei em ambiente produtivo,
**reescritas sobre um domínio fictício de plataforma de compra coletiva**. A
técnica é a mesma; nomes de banco, schemas, tabelas e regras de negócio foram
substituídos, e nenhum dado real está envolvido.

| Arquivo | Técnica |
|---|---|
| [`01_merge_incremental_snowflake.sql`](sql-analytics/01_merge_incremental_snowflake.sql) | Stored procedure com `MERGE` idempotente a partir de JSON em stage externo, com chave composta |
| [`02_ranking_com_split_to_table.sql`](sql-analytics/02_ranking_com_split_to_table.sql) | `LATERAL SPLIT_TO_TABLE` para explodir string em linhas, `ROW_NUMBER` por partição e `LISTAGG` para reconsolidar |
| [`03_segmentacao_clientes_crm.sql`](sql-analytics/03_segmentacao_clientes_crm.sql) | Base de segmentação para automação de marketing: ticket médio, recência, e status por precedência de regras |
| [`04_participantes_por_campanha.sql`](sql-analytics/04_participantes_por_campanha.sql) | Comparação de duas modalidades de compra numa mesma campanha, via agregados unidos por `JOIN` |
| [`05_receita_mensal_por_modalidade.sql`](sql-analytics/05_receita_mensal_por_modalidade.sql) | Série temporal de 24 meses com janela móvel por `DATEDIFF` |

Dois pontos que valem destaque nessas rotinas:

**Idempotência na carga.** O `MERGE` com chave composta permite reexecutar a
carga sem duplicar registro nem perder atualização — requisito para qualquer
pipeline que possa falhar no meio e precisar ser reprocessado.

**Precedência de regras na segmentação.** Em `03`, o status do cliente avalia
opt-out e bloqueios *antes* de qualquer classificação de atividade. Inverter essa
ordem faria comunicação ser enviada a quem pediu descadastro.

---

## Python

| Projeto | O que faz |
|---|---|
| [`web-scraping-wikipedia/`](web-scraping-wikipedia/) | Extrai lista de filmes da Wikipedia com BeautifulSoup e exporta para Excel; inclui implementação recursiva de Fibonacci |
| [`coleta-api-e-scraping/`](coleta-api-e-scraping/) | Coleta de dados combinando consumo de API e scraping |
| [`poo-cadastro-alunos/`](poo-cadastro-alunos/) | Modelagem orientada a objetos com validação de CPF, e-mail e telefone |
| [`analise-geracao-energia/`](analise-geracao-energia/) | Análise de geração por usina a partir dos dados abertos do ONS |

---

## Aplicação

| Projeto | O que faz |
|---|---|
| [`flask-dataframe/`](flask-dataframe/) | Aplicação Flask que renderiza um DataFrame pandas como tabela HTML |

```bash
cd flask-dataframe
pip install flask pandas
python app.py
```

Disponível em `http://localhost:5000`.

---

## Estrutura

```
├── sql-analytics/
├── web-scraping-wikipedia/
├── coleta-api-e-scraping/
├── poo-cadastro-alunos/
├── analise-geracao-energia/
└── flask-dataframe/
    ├── app.py
    └── templates/
```

---

**Rafael Cardoso Nascimento** · [GitHub](https://github.com/RafaelCardoso140701)
