# Correção de Viés no Máximo Drawdown - Ibovespa

Script Julia que analisa o Máximo Drawdown do Ibovespa usando **Jackknife** para correção de viés e **Moving Block Bootstrap** para intervalos de confiança robustos.

## O que faz

O programa baixa dados mensais do Ibovespa (desde 2000) e executa duas análises principais:

1. **Análise de Drawdown (12 meses)** - Usando Jackknife
   - Calcula drawdown empírico em janelas de 12 meses
   - Corrige o viés de subestimação usando técnica Jackknife
   - Mostra quanto o drawdown empírico subestima o risco real

2. **Análise de VaR 99% (24 meses)** - Usando Moving Block Bootstrap  
   - Calcula Value-at-Risk em janelas de 24 meses
   - Preserva dependência temporal dos retornos
   - Fornece intervalos de confiança robustos

## Como Usar

1. **Instalar Julia** (versão 1.6+)
2. **Instalar dependências**:
   ```julia
   using Pkg
   Pkg.add(["DataFrames", "Statistics", "Random", "Plots", "Dates", "YFinance", "HypothesisTests", "Distributions"])
   ```
3. **Executar**:
   ```julia
   julia pq_resampling.jl
   ```

O programa vai baixar automaticamente os dados do Ibovespa e executar as análises.

## Resultados Típicos

**Drawdown (12 meses):**
- Empírico médio: ~16%
- Corrigido (Jackknife): ~27% 
- **Subestimação: ~40%**

**VaR 99% (24 meses):**
- Empírico: ~-38%
- Bootstrap: ~-43%
- IC 95%: [-67%, -16%]

## Por que isso importa

O drawdown empírico **sempre subestima** o risco real, especialmente em períodos curtos. O Jackknife corrige essa subestimação sistemática, fornecendo uma visão mais realista do risco.

## Validação

O programa testa a independência dos retornos usando o teste de Ljung-Box antes de aplicar as técnicas de reamostragem.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

**Desenvolvido para demonstrar a importância das técnicas de reamostragem na análise de risco financeiro.**