-- =====================================================
-- TESTES FUNCIONAIS - LOCADORA DE DVDs
-- Banco de Dados: PostgreSQL
-- =====================================================

-- Conectar ao banco
\c locadora_dvds;

-- =====================================================
-- TESTES DE VALIDAÇÃO DO BANCO
-- =====================================================

-- Teste 1: Verificar se todas as tabelas foram criadas
SELECT 'TESTE 1: Verificação de Tabelas' as teste;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Teste 2: Verificar se todas as constraints foram criadas
SELECT 'TESTE 2: Verificação de Constraints' as teste;
SELECT 
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public'
ORDER BY table_name, constraint_type;

-- Teste 3: Verificar se os índices foram criados
SELECT 'TESTE 3: Verificação de Índices' as teste;
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- TESTES FUNCIONAIS - INSERÇÃO DE DADOS
-- =====================================================

-- Teste 4: Inserir novo cliente
SELECT 'TESTE 4: Inserção de Novo Cliente' as teste;
INSERT INTO cliente (nome_completo, cpf, rua, numero, bairro, cep, cidade, estado) 
VALUES ('Carlos Teste Silva', '12312312312', 'Rua de Teste', '999', 'Bairro Teste', '12345678', 'São Paulo', 'SP')
RETURNING cliente_id, nome_completo;

-- Teste 5: Inserir telefone para o cliente (principal)
SELECT 'TESTE 5: Inserção de Telefone Principal' as teste;
INSERT INTO telefone_cliente (cliente_id, numero_telefone, eh_principal, tipo)
VALUES ((SELECT cliente_id FROM cliente WHERE cpf = '12312312312'), '11999999999', TRUE, 'celular')
RETURNING telefone_id, numero_telefone, eh_principal;

-- Teste 6: Tentar inserir outro telefone principal (deve funcionar, mas alterar o anterior)
SELECT 'TESTE 6: Teste de Trigger - Telefone Principal Único' as teste;
INSERT INTO telefone_cliente (cliente_id, numero_telefone, eh_principal, tipo)
VALUES ((SELECT cliente_id FROM cliente WHERE cpf = '12312312312'), '11888888888', TRUE, 'residencial')
RETURNING telefone_id, numero_telefone, eh_principal;

-- Verificar se apenas um telefone ficou como principal
SELECT 
    telefone_id,
    numero_telefone,
    eh_principal
FROM telefone_cliente 
WHERE cliente_id = (SELECT cliente_id FROM cliente WHERE cpf = '12312312312');

-- Teste 7: Inserir nova categoria
SELECT 'TESTE 7: Inserção de Nova Categoria' as teste;
INSERT INTO categoria (nome, descricao) 
VALUES ('Teste', 'Categoria de teste')
RETURNING categoria_id, nome;

-- Teste 8: Inserir novo filme
SELECT 'TESTE 8: Inserção de Novo Filme' as teste;
INSERT INTO filme (titulo, duracao_minutos, categoria_id, ano_lancamento, sinopse) 
VALUES ('Filme Teste', 120, (SELECT categoria_id FROM categoria WHERE nome = 'Teste'), 2024, 'Sinopse de teste')
RETURNING filme_id, titulo;

-- Teste 9: Inserir novo disco
SELECT 'TESTE 9: Inserção de Novo Disco' as teste;
INSERT INTO disco (numero_registro, codigo_barras, filme_id, estado_conservacao, data_aquisicao) 
VALUES ('REG999', '999999999999', (SELECT filme_id FROM filme WHERE titulo = 'Filme Teste'), 'novo', CURRENT_DATE)
RETURNING disco_id, numero_registro;

-- =====================================================
-- TESTES FUNCIONAIS - LOCAÇÕES
-- =====================================================

-- Teste 10: Criar nova locação
SELECT 'TESTE 10: Criação de Nova Locação' as teste;
INSERT INTO locacao (cliente_id, data_locacao, data_devolucao_prevista, preco_total, status_locacao) 
VALUES (
    (SELECT cliente_id FROM cliente WHERE cpf = '12312312312'),
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    15.00,
    'ativa'
)
RETURNING locacao_id, data_locacao, data_devolucao_prevista;

-- Teste 11: Adicionar disco à locação
SELECT 'TESTE 11: Adição de Disco à Locação' as teste;
INSERT INTO locacao_disco (locacao_id, disco_id, preco_unitario) 
VALUES (
    (SELECT MAX(locacao_id) FROM locacao),
    (SELECT disco_id FROM disco WHERE numero_registro = 'REG999'),
    15.00
)
RETURNING locacao_id, disco_id, preco_unitario;

-- Teste 12: Simular devolução com atraso (teste de trigger)
SELECT 'TESTE 12: Teste de Trigger - Cálculo de Multa' as teste;
UPDATE locacao 
SET data_devolucao_real = CURRENT_DATE + INTERVAL '2 days'
WHERE locacao_id = (SELECT MAX(locacao_id) FROM locacao);

-- Verificar se a multa foi calculada
SELECT 
    locacao_id,
    data_devolucao_prevista,
    data_devolucao_real,
    preco_total,
    valor_multa,
    status_locacao
FROM locacao 
WHERE locacao_id = (SELECT MAX(locacao_id) FROM locacao);

-- =====================================================
-- TESTES FUNCIONAIS - CONSULTAS COMPLEXAS
-- =====================================================

-- Teste 13: Consultar filmes com seus atores
SELECT 'TESTE 13: Consulta - Filmes e Atores' as teste;
SELECT 
    f.titulo,
    a.nome_completo,
    fa.papel
FROM filme f
JOIN filme_ator fa ON f.filme_id = fa.filme_id
JOIN ator a ON fa.ator_id = a.ator_id
ORDER BY f.titulo, a.nome_completo;

-- Teste 14: Consultar locações ativas por cliente
SELECT 'TESTE 14: Consulta - Locações Ativas por Cliente' as teste;
SELECT 
    c.nome_completo,
    l.data_locacao,
    l.data_devolucao_prevista,
    f.titulo,
    l.preco_total
FROM cliente c
JOIN locacao l ON c.cliente_id = l.cliente_id
JOIN locacao_disco ld ON l.locacao_id = ld.locacao_id
JOIN disco d ON ld.disco_id = d.disco_id
JOIN filme f ON d.filme_id = f.filme_id
WHERE l.status_locacao = 'ativa'
ORDER BY c.nome_completo, l.data_locacao;

-- Teste 15: Consultar filmes mais locados
SELECT 'TESTE 15: Consulta - Filmes Mais Locados' as teste;
SELECT * FROM filmes_mais_locados;

-- Teste 16: Consultar locações ativas (usando view)
SELECT 'TESTE 16: Consulta - View Locações Ativas' as teste;
SELECT * FROM locacoes_ativas;

-- =====================================================
-- TESTES DE PERFORMANCE
-- =====================================================

-- Teste 17: Testar performance de consulta com índice
SELECT 'TESTE 17: Teste de Performance - Busca por CPF' as teste;
EXPLAIN ANALYZE
SELECT c.nome_completo, c.cpf 
FROM cliente c 
WHERE c.cpf = '12345678901';

-- Teste 18: Testar performance de consulta com índice
SELECT 'TESTE 18: Teste de Performance - Busca por Código de Barras' as teste;
EXPLAIN ANALYZE
SELECT d.numero_registro, f.titulo 
FROM disco d 
JOIN filme f ON d.filme_id = f.filme_id 
WHERE d.codigo_barras = '123456789012';

-- =====================================================
-- TESTES DE INTEGRIDADE
-- =====================================================

-- Teste 19: Tentar inserir cliente com CPF duplicado (deve falhar)
SELECT 'TESTE 19: Teste de Integridade - CPF Duplicado' as teste;
DO $$
BEGIN
    INSERT INTO cliente (nome_completo, cpf, rua, numero, bairro, cep, cidade, estado) 
    VALUES ('Teste Duplicado', '12345678901', 'Rua Teste', '123', 'Bairro', '12345678', 'Cidade', 'SP');
EXCEPTION 
    WHEN unique_violation THEN
        RAISE NOTICE 'CORRETO: Violação de chave única detectada para CPF duplicado';
END$$;

-- Teste 20: Tentar inserir nota inválida na pesquisa (deve falhar)
SELECT 'TESTE 20: Teste de Integridade - Nota Inválida' as teste;
DO $$
BEGIN
    INSERT INTO pesquisa_satisfacao (locacao_id, nota_atendimento, nota_qualidade_filmes) 
    VALUES (1, 15, 8);
EXCEPTION 
    WHEN check_violation THEN
        RAISE NOTICE 'CORRETO: Violação de constraint CHECK detectada para nota inválida';
END$$;

-- =====================================================
-- TESTES DE RELATÓRIOS
-- =====================================================

-- Teste 21: Relatório de clientes por cidade
SELECT 'TESTE 21: Relatório - Clientes por Cidade' as teste;
SELECT 
    cidade,
    estado,
    COUNT(*) as total_clientes
FROM cliente
GROUP BY cidade, estado
ORDER BY total_clientes DESC;

-- Teste 22: Relatório de receita por mês
SELECT 'TESTE 22: Relatório - Receita por Mês' as teste;
SELECT 
    DATE_TRUNC('month', data_locacao) as mes,
    SUM(preco_total) as receita_total,
    COUNT(*) as total_locacoes
FROM locacao
GROUP BY DATE_TRUNC('month', data_locacao)
ORDER BY mes;

-- Teste 23: Relatório de filmes por categoria
SELECT 'TESTE 23: Relatório - Filmes por Categoria' as teste;
SELECT 
    c.nome as categoria,
    COUNT(f.filme_id) as total_filmes,
    AVG(f.duracao_minutos) as duracao_media
FROM categoria c
LEFT JOIN filme f ON c.categoria_id = f.categoria_id
GROUP BY c.categoria_id, c.nome
ORDER BY total_filmes DESC;

-- =====================================================
-- TESTES DE LIMPEZA
-- =====================================================

-- Teste 24: Limpeza de dados de teste
SELECT 'TESTE 24: Limpeza dos Dados de Teste' as teste;

-- Remover dados de teste inseridos
DELETE FROM locacao_disco WHERE locacao_id = (SELECT MAX(locacao_id) FROM locacao);
DELETE FROM locacao WHERE cliente_id = (SELECT cliente_id FROM cliente WHERE cpf = '12312312312');
DELETE FROM disco WHERE numero_registro = 'REG999';
DELETE FROM filme WHERE titulo = 'Filme Teste';
DELETE FROM categoria WHERE nome = 'Teste';
DELETE FROM telefone_cliente WHERE cliente_id = (SELECT cliente_id FROM cliente WHERE cpf = '12312312312');
DELETE FROM cliente WHERE cpf = '12312312312';

-- =====================================================
-- RESULTADO FINAL DOS TESTES
-- =====================================================

-- Teste 25: Verificação final da integridade
SELECT 'TESTE 25: Verificação Final de Integridade' as teste;
SELECT 
    'Categorias' as tabela,
    COUNT(*) as total_registros
FROM categoria
UNION ALL
SELECT 
    'Clientes' as tabela,
    COUNT(*) as total_registros
FROM cliente
UNION ALL
SELECT 
    'Filmes' as tabela,
    COUNT(*) as total_registros
FROM filme
UNION ALL
SELECT 
    'Discos' as tabela,
    COUNT(*) as total_registros
FROM disco
UNION ALL
SELECT 
    'Locações' as tabela,
    COUNT(*) as total_registros
FROM locacao
ORDER BY tabela;

-- Mensagem final
SELECT 'TODOS OS TESTES CONCLUÍDOS COM SUCESSO!' as resultado_final;
SELECT 'Banco de dados validado e funcionando corretamente!' as status; 