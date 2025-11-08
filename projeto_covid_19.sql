-- ####################################################################
-- PROJETO 4: ANÁLISE DE SAÚDE PÚBLICA (SQL SERVER - WINDOW FUNCTIONS)
-- Objetivo: Demonstrar comandos essenciais e análise de tendências (Júnior/Pleno).
-- ####################################################################

-- Atenção: A coluna 'date' deve estar em formato DATE/DATETIME e as colunas de contagem como FLOAT para que o CAST funcione.

-- ====================================================================
-- 5 CONSULTAS BÁSICAS (Comandos Essenciais)
-- ====================================================================

-- CB 1: SELECIONAR (Verificar o cabeçalho e as primeiras 5 linhas da tabela)
SELECT TOP 5 * FROM DadosCovid;

-- ---
-- CB 2: FILTRAR (Contar a quantidade de dias/linhas de dados disponíveis apenas para o Brasil)
SELECT 
    COUNT(*) AS total_dias_brasil
FROM 
    DadosCovid
WHERE 
    location = 'Brazil';

-- ---
-- CB 3: AGRUPAR (Contar quantas linhas de dados existem por continente, e ordenar)
SELECT 
    continent, 
    COUNT(*) AS total_linhas
FROM 
    DadosCovid
WHERE 
    continent IS NOT NULL 
GROUP BY 
    continent
ORDER BY
    total_linhas DESC;

-- ---
-- CB 4: FILTRAR E COMPARAR TEXTO (Listar países com a palavra "South" no nome)
SELECT 
    DISTINCT location 
FROM 
    DadosCovid
WHERE 
    location LIKE 'South%';
    
-- ---
-- CB 5: ORDENAR (Encontrar a data mais recente neste dataset)
SELECT TOP 1
    date
FROM 
    DadosCovid
ORDER BY 
    date DESC;


-- ====================================================================
-- 3 CONSULTAS INTERMEDIÁRIAS (Window Functions - SQL Server)
-- Necessário manter o CAST devido à importação do CSV
-- ====================================================================

-- CI 1: Média Móvel de 7 Dias (AVG() OVER) - Revela a tendência real
SELECT
    location,
    date,
    CAST(new_cases AS FLOAT) AS casos_novos_diario,
    
    -- Calcula a média dos novos casos dos 7 dias (6 anteriores + 1 atual)
    AVG(CAST(new_cases AS FLOAT)) OVER (
        PARTITION BY location  -- Separa o cálculo por país
        ORDER BY date         
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW -- Define a janela de 7 dias
    ) AS media_movel_7dias
FROM
    DadosCovid
WHERE
    location = 'Brazil'
ORDER BY
    date;

-- ---
-- CI 2: Total Acumulado (SUM() OVER) - Mede o crescimento histórico
SELECT
    location,
    date,
    total_cases, 
    
    -- Calcula a SOMA acumulada de todos os novos casos dia após dia
    SUM(CAST(new_cases AS FLOAT)) OVER (
        PARTITION BY location  -- Garante que a soma é só do Brasil
        ORDER BY date         
    ) AS total_acumulado_new_cases
FROM
    DadosCovid
WHERE
    location = 'Brazil'
ORDER BY
    date;

-- ---
-- CI 3: Variação Diária (LAG()) - Mede a aceleração da pandemia
SELECT
    location,
    date,
    CAST(new_cases AS FLOAT) AS casos_novos_hoje,
    
    -- Busca o valor de 'new_cases' da linha ANTERIOR (dia anterior)
    LAG(CAST(new_cases AS FLOAT), 1, 0) OVER (
        PARTITION BY location
        ORDER BY date
    ) AS casos_novos_dia_anterior,
    
    -- Calcula a diferença: (Hoje) - (Ontem)
    CAST(new_cases AS FLOAT) - LAG(CAST(new_cases AS FLOAT), 1, 0) OVER (
        PARTITION BY location
        ORDER BY date
    ) AS variacao_diaria_delta
FROM
    DadosCovid
WHERE
    location = 'Brazil' AND new_cases IS NOT NULL
ORDER BY
    date;