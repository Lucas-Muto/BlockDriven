-- Tabela CATEGORIA
CREATE TABLE categoria (
    categoria_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL,
    descricao TEXT
);

-- Tabela CLIENTE
CREATE TABLE cliente (
    cliente_id SERIAL PRIMARY KEY,
    nome_completo VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    rua VARCHAR(100) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    complemento VARCHAR(50),
    bairro VARCHAR(50) NOT NULL,
    cep VARCHAR(8) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela TELEFONE_CLIENTE
CREATE TABLE telefone_cliente (
    telefone_id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    numero_telefone VARCHAR(15) NOT NULL,
    eh_principal BOOLEAN DEFAULT FALSE,
    tipo VARCHAR(20) CHECK (tipo IN ('residencial', 'celular', 'comercial')),
    FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id) ON DELETE CASCADE
);

-- Tabela ATOR
CREATE TABLE ator (
    ator_id SERIAL PRIMARY KEY,
    nome_completo VARCHAR(100) NOT NULL,
    data_nascimento DATE,
    pais_origem VARCHAR(50),
    biografia TEXT
);

-- Tabela FILME
CREATE TABLE filme (
    filme_id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    duracao_minutos INTEGER NOT NULL CHECK (duracao_minutos > 0),
    categoria_id INTEGER NOT NULL,
    ano_lancamento INTEGER CHECK (ano_lancamento > 1900),
    sinopse TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categoria(categoria_id)
);

-- Tabela FILME_ATOR (Associativa)
CREATE TABLE filme_ator (
    filme_id INTEGER NOT NULL,
    ator_id INTEGER NOT NULL,
    papel VARCHAR(100) CHECK (papel IN ('protagonista', 'coadjuvante', 'participacao_especial')),
    PRIMARY KEY (filme_id, ator_id),
    FOREIGN KEY (filme_id) REFERENCES filme(filme_id) ON DELETE CASCADE,
    FOREIGN KEY (ator_id) REFERENCES ator(ator_id) ON DELETE CASCADE
);

-- Tabela DISCO
CREATE TABLE disco (
    disco_id SERIAL PRIMARY KEY,
    numero_registro VARCHAR(20) UNIQUE NOT NULL,
    codigo_barras VARCHAR(50) UNIQUE NOT NULL,
    filme_id INTEGER NOT NULL,
    estado_conservacao VARCHAR(20) CHECK (estado_conservacao IN ('novo', 'bom', 'regular', 'ruim')),
    data_aquisicao DATE,
    esta_disponivel BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (filme_id) REFERENCES filme(filme_id)
);

-- Tabela LOCACAO
CREATE TABLE locacao (
    locacao_id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    data_locacao DATE NOT NULL,
    data_devolucao_prevista DATE NOT NULL,
    data_devolucao_real DATE,
    preco_total DECIMAL(10,2) NOT NULL CHECK (preco_total >= 0),
    valor_multa DECIMAL(10,2) DEFAULT 0.00 CHECK (valor_multa >= 0),
    status_locacao VARCHAR(20) CHECK (status_locacao IN ('ativa', 'devolvida', 'atrasada')),
    FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id),
    CHECK (data_devolucao_prevista > data_locacao)
);

-- Tabela LOCACAO_DISCO (Associativa)
CREATE TABLE locacao_disco (
    locacao_id INTEGER NOT NULL,
    disco_id INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    PRIMARY KEY (locacao_id, disco_id),
    FOREIGN KEY (locacao_id) REFERENCES locacao(locacao_id) ON DELETE CASCADE,
    FOREIGN KEY (disco_id) REFERENCES disco(disco_id)
);

-- Tabela PESQUISA_SATISFACAO
CREATE TABLE pesquisa_satisfacao (
    pesquisa_id SERIAL PRIMARY KEY,
    locacao_id INTEGER UNIQUE NOT NULL,
    nota_atendimento INTEGER CHECK (nota_atendimento >= 0 AND nota_atendimento <= 10),
    nota_qualidade_filmes INTEGER CHECK (nota_qualidade_filmes >= 0 AND nota_qualidade_filmes <= 10),
    comentario TEXT,
    data_pesquisa TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (locacao_id) REFERENCES locacao(locacao_id)
);

-- =====================================================
-- 2. CRIAÇÃO DE ÍNDICES
-- =====================================================

CREATE INDEX idx_cliente_cpf ON cliente(cpf);
CREATE INDEX idx_disco_codigo_barras ON disco(codigo_barras);
CREATE INDEX idx_locacao_data ON locacao(data_locacao);
CREATE INDEX idx_locacao_cliente ON locacao(cliente_id);
CREATE INDEX idx_filme_titulo ON filme(titulo);
CREATE INDEX idx_disco_disponivel ON disco(esta_disponivel);
CREATE INDEX idx_telefone_cliente ON telefone_cliente(cliente_id);
CREATE INDEX idx_filme_categoria ON filme(categoria_id);

-- =====================================================
-- 3. FUNCTIONS E TRIGGERS
-- =====================================================

-- Function para validar telefone principal único por cliente
CREATE OR REPLACE FUNCTION validar_telefone_principal()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.eh_principal = TRUE THEN
        UPDATE telefone_cliente 
        SET eh_principal = FALSE 
        WHERE cliente_id = NEW.cliente_id AND telefone_id != NEW.telefone_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para telefone principal
CREATE TRIGGER trigger_telefone_principal
    BEFORE INSERT OR UPDATE ON telefone_cliente
    FOR EACH ROW
    EXECUTE FUNCTION validar_telefone_principal();

-- Function para calcular multa automaticamente
CREATE OR REPLACE FUNCTION calcular_multa()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_devolucao_real IS NOT NULL AND NEW.data_devolucao_real > NEW.data_devolucao_prevista THEN
        NEW.valor_multa := NEW.preco_total * 0.1 * (NEW.data_devolucao_real - NEW.data_devolucao_prevista);
        NEW.status_locacao := 'devolvida';
    ELSIF NEW.data_devolucao_real IS NOT NULL THEN
        NEW.status_locacao := 'devolvida';
    ELSIF CURRENT_DATE > NEW.data_devolucao_prevista THEN
        NEW.status_locacao := 'atrasada';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para calcular multa
CREATE TRIGGER trigger_calcular_multa
    BEFORE UPDATE ON locacao
    FOR EACH ROW
    EXECUTE FUNCTION calcular_multa();

-- =====================================================
-- 4. INSERÇÃO DE DADOS DE EXEMPLO
-- =====================================================

-- Inserindo Categorias
INSERT INTO categoria (nome, descricao) VALUES 
('Ação', 'Filmes com muita ação e aventura'),
('Comédia', 'Filmes divertidos e engraçados'),
('Drama', 'Filmes dramáticos e emocionantes'),
('Terror', 'Filmes de suspense e terror'),
('Romance', 'Filmes românticos'),
('Ficção Científica', 'Filmes futuristas e sci-fi'),
('Animação', 'Filmes de animação'),
('Documentário', 'Documentários educativos');

-- Inserindo Atores
INSERT INTO ator (nome_completo, data_nascimento, pais_origem, biografia) VALUES 
('Leonardo DiCaprio', '1974-11-11', 'Estados Unidos', 'Ator americano famoso por seus papéis em filmes como Titanic e Inception'),
('Meryl Streep', '1949-06-22', 'Estados Unidos', 'Atriz americana considerada uma das melhores de sua geração'),
('Robert De Niro', '1943-08-17', 'Estados Unidos', 'Ator americano conhecido por filmes como Taxi Driver e Goodfellas'),
('Scarlett Johansson', '1984-11-22', 'Estados Unidos', 'Atriz americana conhecida por filmes de ação e drama'),
('Morgan Freeman', '1937-06-01', 'Estados Unidos', 'Ator americano com voz marcante e grandes performances');

-- Inserindo Filmes
INSERT INTO filme (titulo, duracao_minutos, categoria_id, ano_lancamento, sinopse) VALUES 
('Inception', 148, 6, 2010, 'Um ladrão que invade sonhos recebe a tarefa de plantar uma ideia na mente de alguém'),
('Titanic', 195, 5, 1997, 'Romance épico sobre o naufrágio do famoso navio'),
('Taxi Driver', 114, 3, 1976, 'Um taxista solitário em Nova York planeja um ato violento'),
('Os Vingadores', 143, 1, 2012, 'Super-heróis se unem para salvar o mundo'),
('Toy Story', 81, 7, 1995, 'Brinquedos ganham vida quando humanos não estão por perto');

-- Inserindo Filme_Ator
INSERT INTO filme_ator (filme_id, ator_id, papel) VALUES 
(1, 1, 'protagonista'),
(2, 1, 'protagonista'),
(3, 3, 'protagonista'),
(4, 4, 'coadjuvante'),
(1, 5, 'coadjuvante');

-- Inserindo Discos
INSERT INTO disco (numero_registro, codigo_barras, filme_id, estado_conservacao, data_aquisicao, esta_disponivel) VALUES 
('REG001', '123456789012', 1, 'novo', '2024-01-15', TRUE),
('REG002', '123456789013', 1, 'bom', '2024-01-15', TRUE),
('REG003', '123456789014', 2, 'novo', '2024-01-20', TRUE),
('REG004', '123456789015', 3, 'bom', '2024-01-25', TRUE),
('REG005', '123456789016', 4, 'novo', '2024-02-01', TRUE),
('REG006', '123456789017', 5, 'bom', '2024-02-05', TRUE);

-- Inserindo Clientes
INSERT INTO cliente (nome_completo, cpf, rua, numero, complemento, bairro, cep, cidade, estado) VALUES 
('João Silva Santos', '12345678901', 'Rua das Flores', '123', 'Apto 101', 'Centro', '01234567', 'São Paulo', 'SP'),
('Maria Oliveira Costa', '98765432100', 'Avenida Paulista', '456', NULL, 'Bela Vista', '01310100', 'São Paulo', 'SP'),
('Pedro Santos Lima', '11122233344', 'Rua Augusta', '789', 'Casa 2', 'Consolação', '01305000', 'São Paulo', 'SP'),
('Ana Costa Ferreira', '55566677788', 'Rua Oscar Freire', '321', 'Loja 1', 'Jardins', '01426000', 'São Paulo', 'SP');

-- Inserindo Telefones
INSERT INTO telefone_cliente (cliente_id, numero_telefone, eh_principal, tipo) VALUES 
(1, '11987654321', TRUE, 'celular'),
(1, '1134567890', FALSE, 'residencial'),
(2, '11976543210', TRUE, 'celular'),
(3, '11965432109', TRUE, 'celular'),
(3, '1145678901', FALSE, 'comercial'),
(4, '11954321098', TRUE, 'celular');

-- Inserindo Locações
INSERT INTO locacao (cliente_id, data_locacao, data_devolucao_prevista, preco_total, status_locacao) VALUES 
(1, '2024-03-01', '2024-03-08', 15.00, 'ativa'),
(2, '2024-03-02', '2024-03-09', 20.00, 'ativa'),
(3, '2024-02-25', '2024-03-04', 10.00, 'devolvida'),
(4, '2024-03-03', '2024-03-10', 25.00, 'ativa');

-- Inserindo Locação_Disco
INSERT INTO locacao_disco (locacao_id, disco_id, preco_unitario) VALUES 
(1, 1, 15.00),
(2, 2, 10.00),
(2, 3, 10.00),
(3, 4, 10.00),
(4, 5, 15.00),
(4, 6, 10.00);

-- Inserindo Pesquisa de Satisfação
INSERT INTO pesquisa_satisfacao (locacao_id, nota_atendimento, nota_qualidade_filmes, comentario) VALUES 
(3, 9, 8, 'Ótimo atendimento, filme de boa qualidade');

-- =====================================================
-- 5. VIEWS ÚTEIS
-- =====================================================

-- View para consultar locações ativas
CREATE VIEW locacoes_ativas AS
SELECT 
    l.locacao_id,
    c.nome_completo,
    c.cpf,
    l.data_locacao,
    l.data_devolucao_prevista,
    l.preco_total,
    CASE 
        WHEN l.data_devolucao_prevista < CURRENT_DATE THEN 'ATRASADA'
        ELSE 'NO PRAZO'
    END AS situacao
FROM locacao l
JOIN cliente c ON l.cliente_id = c.cliente_id
WHERE l.status_locacao = 'ativa';

-- View para relatório de filmes mais locados
CREATE VIEW filmes_mais_locados AS
SELECT 
    f.titulo,
    cat.nome as categoria,
    COUNT(ld.disco_id) as total_locacoes
FROM filme f
JOIN categoria cat ON f.categoria_id = cat.categoria_id
JOIN disco d ON f.filme_id = d.filme_id
JOIN locacao_disco ld ON d.disco_id = ld.disco_id
GROUP BY f.filme_id, f.titulo, cat.nome
ORDER BY total_locacoes DESC;

-- =====================================================
-- 6. CONSULTAS DE EXEMPLO
-- =====================================================

-- Consulta 1: Clientes com locações ativas
SELECT 
    c.nome_completo,
    c.cpf,
    COUNT(l.locacao_id) as locacoes_ativas
FROM cliente c
JOIN locacao l ON c.cliente_id = l.cliente_id
WHERE l.status_locacao = 'ativa'
GROUP BY c.cliente_id, c.nome_completo, c.cpf;

-- Consulta 2: Filmes por categoria
SELECT 
    cat.nome as categoria,
    COUNT(f.filme_id) as quantidade_filmes
FROM categoria cat
LEFT JOIN filme f ON cat.categoria_id = f.categoria_id
GROUP BY cat.categoria_id, cat.nome
ORDER BY quantidade_filmes DESC;

-- Consulta 3: Atores e seus filmes
SELECT 
    a.nome_completo,
    f.titulo,
    fa.papel
FROM ator a
JOIN filme_ator fa ON a.ator_id = fa.ator_id
JOIN filme f ON fa.filme_id = f.filme_id
ORDER BY a.nome_completo;

-- Verificar se tudo foi criado corretamente
SELECT 'Banco de dados criado com sucesso!' as status; 