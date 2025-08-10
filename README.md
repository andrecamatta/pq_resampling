# PQ Resampling - Análise de Máximo Drawdown com Técnicas de Reamostragem

Este projeto demonstra a aplicação de técnicas de reamostragem (Jackknife e Bootstrap) para correção de viés em análises de risco financeiro, focando especificamente na análise do Máximo Drawdown do Índice Bovespa.

## 🎯 Objetivo

Demonstrar como o **drawdown empírico sempre subestima o risco real** e como técnicas estatísticas avançadas podem fornecer estimativas mais precisas e confiáveis para gestão de risco.

## 📊 Funcionalidades

### Análise Principal
- **Máximo Drawdown do Ibovespa**: Análise completa usando dados mensais históricos
- **Correção de Viés com Jackknife**: Identifica e corrige a subestimação sistemática do drawdown empírico
- **Intervalos de Confiança com Bootstrap**: Fornece intervalos robustos preservando dependência temporal
- **VaR 99% com Moving Block Bootstrap**: Análise de Value-at-Risk considerando autocorrelação

### Validação Estatística
- **Teste de Ljung-Box**: Verificação de independência dos retornos
- **Análise de Janelas Deslizantes**: Estudo do viés em diferentes períodos
- **Comparação de Métricas**: Drawdown vs VaR para gestão de risco completa

## 🚀 Como Usar

### Pré-requisitos
- Julia 1.6 ou superior
- Conexão com internet (para download de dados do Yahoo Finance)

### Dependências
```julia
using DataFrames, Statistics, Random, Plots, Dates, YFinance, HypothesisTests, Distributions
```

### Instalação das Dependências
```julia
using Pkg
Pkg.add(["DataFrames", "Statistics", "Random", "Plots", "Dates", "YFinance"])
```

### Executar a Análise
```julia
julia pq_resampling.jl
```

## 📈 Principais Resultados

### Correção de Viés
- **Problema**: Drawdown empírico subestima perdas futuras em 10-30%
- **Solução**: Jackknife fornece estimativa corrigida mais realista
- **Aplicação**: Essencial para períodos < 5 anos de dados

### Gestão de Risco
- **Drawdown Corrigido**: Para planejamento de longo prazo
- **VaR 99% Bootstrap**: Para gestão de risco mensal
- **Intervalos de Confiança**: Para cenários de stress testing

## 🔬 Metodologia

### 1. Jackknife para Drawdown
- Corrige viés sistemático de subestimação
- Fornece erro padrão da estimativa
- Especialmente útil para amostras pequenas

### 2. Moving Block Bootstrap
- Preserva estrutura de dependência temporal
- Gera intervalos de confiança robustos
- Apropriado para séries temporais financeiras

### 3. Validação de Pressupostos
- Teste de independência dos retornos
- Verificação de adequação dos métodos
- Diagnóstico de autocorrelação

## 📋 Estrutura dos Resultados

### Análise de Drawdown (12 meses)
```
📉 Drawdown empírico médio: X.XX%
📈 Drawdown corrigido médio: Y.YY%
⚠️  Subestimação média: Z.Z%
```

### Análise de VaR (24 meses)
```
📊 VaR 99% empírico: X.XX%
📊 VaR 99% bootstrap: Y.YY%
📊 IC 95%: [A.AA%, B.BB%]
```

## 🎯 Aplicações Práticas

### Para Gestores de Risco
- Use drawdown corrigido em relatórios para investidores
- Considere IC superior para gestão de capital
- Combine métricas para visão completa de risco

### Para Reguladores
- Jackknife melhora precisão em relatórios regulatórios
- Bootstrap fornece cenários de stress testing
- Métodos estatisticamente fundamentados

### Para Pesquisadores
- Demonstração prática de correção de viés
- Comparação de técnicas de reamostragem
- Aplicação em dados financeiros reais

## ⚠️ Considerações Importantes

### Quando Usar Jackknife
- **SEMPRE** em amostras < 5 anos
- Quando precisão na estimativa de risco é crítica
- Para validação de modelos de risco
- Em relatórios regulatórios

### Limitações
- Requer dados suficientes (mínimo 120 observações mensais)
- Pressupõe estrutura de dependência estável
- Resultados dependem da qualidade dos dados históricos

## 💡 Lição Principal

**O drawdown que você viu no passado provavelmente SUBESTIMA o drawdown que você verá no futuro!**

Use técnicas de reamostragem para ter uma visão mais realista e estatisticamente fundamentada do risco.

## 📚 Base Teórica

Este projeto baseia-se nos trabalhos fundamentais sobre:
- Técnicas de reamostragem de Efron (Bootstrap) e Quenouille (Jackknife)
- Análise de séries temporais financeiras
- Métrica de risco e drawdown analysis
- Moving block bootstrap para séries dependentes

## 🤝 Contribuições

Contribuições são bem-vindas! Especialmente:
- Extensões para outros índices e mercados
- Implementação de outras métricas de risco
- Melhorias na visualização dos resultados
- Testes adicionais de robustez

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

**Desenvolvido para demonstrar a importância das técnicas de reamostragem na análise de risco financeiro.**