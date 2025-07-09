# 🎬 Projeto: Modelagem de Banco de Dados - Locadora de DVDs

## 📖 Visão Geral

Modelagem completa de banco de dados para locadora de DVDs em PostgreSQL, com foco em automações inteligentes, validações rigorosas e estruturas otimizadas.

## 🎥 Vídeo Explicativo

**🔗 [Assista ao vídeo explicativo do projeto](https://drive.google.com/file/d/1OmPDdie5FBMgRZpyHieKpiFpjLWCcWIj/view?usp=sharing)**

## 📂 Estrutura do Projeto

```
BlockDriven/
├── README.md                     # Documentação principal
├── locadora_dvds.sql             # Script SQL completo
├── testes_funcionais.sql         # Testes de validação
```

## 🗂️ Modelo de Dados

### 📊 **Entidades Principais**
1. **CLIENTE** - Cadastro com múltiplos telefones
2. **FILME** - Catálogo com categorias e atores
3. **DISCO** - Cópias físicas individuais
4. **LOCAÇÃO** - Sistema de aluguel múltiplo
5. **PESQUISA_SATISFAÇÃO** - Feedback dos clientes

### 🔗 **Relacionamentos Implementados**
1. **Cliente ↔ Locação** (1:N)
2. **Cliente ↔ Telefone_Cliente** (1:N)
3. **Filme ↔ Disco** (1:N)
4. **Locação ↔ Locação_Disco ↔ Disco** (N:M)
5. **Filme ↔ Filme_Ator ↔ Ator** (N:M)
6. **Locação ↔ Pesquisa_Satisfação** (1:1)
7. **Filme ↔ Categoria** (N:1)

## 🚀 Como Executar

### **1. Configurar Ambiente**
```bash
# Pré-requisitos
PostgreSQL 12+
PgAdmin 4.30+
```

### **2. Executar Script**
```sql
-- No PgAdmin
psql -U postgres -f locadora_dvds.sql
```

### **3. Validar Funcionamento**
```sql
-- Executar testes
psql -U postgres -d locadora_dvds -f testes_funcionais.sql
```

## 📊 Principais Decisões Técnicas

### **1. Separação FILME vs DISCO**
Um filme pode ter várias cópias físicas, cada uma com controle individual de disponibilidade.

### **2. Múltiplos Telefones por Cliente**
Tabela separada com trigger garantindo apenas um telefone principal.

### **3. Cálculo Automático de Multas**
Trigger que calcula multas automaticamente: `preço total × 0.1 × dias de atraso`

### **4. Relacionamentos N:M**
Tabelas associativas para filme-ator e locação-disco com campos adicionais.

### **5. Pesquisa de Satisfação 1:1**
Relacionamento exclusivo com locação para feedback dos clientes.

## 🔧 Funcionalidades Implementadas

### **Automações**
- **Trigger**: Telefone principal único por cliente
- **Trigger**: Cálculo automático de multas por atraso
- **Constraints**: Validações de integridade de dados
- **Views**: Consultas pré-definidas para relatórios

### **Otimizações**
- Índices estratégicos em campos críticos
- Relacionamentos bem definidos
- Normalização adequada
- Tipos de dados apropriados

## 📋 Exemplos de Uso

### **Consultas Básicas**
```sql
-- Locações ativas
SELECT * FROM locacoes_ativas;

-- Filmes por categoria
SELECT f.titulo, c.nome as categoria
FROM filme f
JOIN categoria c ON f.categoria_id = c.categoria_id;
```

### **Relatórios Gerenciais**
```sql
-- Receita mensal
SELECT 
    DATE_TRUNC('month', data_locacao) as mes,
    SUM(preco_total) as receita
FROM locacao
GROUP BY DATE_TRUNC('month', data_locacao);
```

## 🔍 Testes e Validação

### **Cenários Testados**
- Integridade referencial
- Constraints e validações
- Triggers funcionais
- Performance de consultas
- Cálculo de multas
- Inserção de dados válidos/inválidos
- Múltiplos telefones por cliente
- Locações com múltiplos discos
- Pesquisa de satisfação

## 📈 Benefícios da Modelagem

### **Operacionais**
- Controle individual de cada disco
- Cálculo automático de multas
- Relatórios automáticos
- Redução de erros manuais

### **Técnicos**
- Estrutura normalizada
- Performance otimizada
- Integridade garantida
- Facilmente extensível

## 🎯 Status do Projeto

### **Entregáveis Finalizados**
- Modelo do banco (estrutura completa)
- Script SQL executável
- Vídeo explicativo gravado
- Documentação técnica completa
- Testes funcionais validados

### **Destaques**
- Automações inteligentes
- Validações rigorosas
- Estruturas otimizadas
- Código limpo e documentado
- Preparado para produção

---

**🎬 Projeto desenvolvido para disciplina de Banco de Dados**  
**📊 Foco: Modelagem completa com PostgreSQL**  
**✅ Status: COMPLETO E TESTADO**  
**🎥 [Link do vídeo explicativo](https://drive.google.com/file/d/1OmPDdie5FBMgRZpyHieKpiFpjLWCcWIj/view?usp=sharing)** 