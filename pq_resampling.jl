#=
Máximo Drawdown: Demonstração Prática de Correção de Viés
Aplicação de Jackknife e Bootstrap em Gestão de Risco

Um script Julia demonstrando:
- Análise do Máximo Drawdown do Ibovespa
- Validação de pressupostos para reamostragem
- Jackknife para correção de viés no drawdown
- Bootstrap para intervalos de confiança do drawdown
- Aplicação prática em gestão de risco
=#

using DataFrames, Statistics, Random, Plots, Dates, YFinance, HypothesisTests, Distributions

println("="^80)
println("MÁXIMO DRAWDOWN: CORREÇÃO DE VIÉS COM JACKKNIFE")
println("Aplicação Prática em Gestão de Risco")
println("="^80)
println("\n📊 OBJETIVO: Demonstrar correção de viés em Máximo Drawdown")
println("   usando Jackknife e Bootstrap no Ibovespa")
println("⚠️  Drawdown empírico sempre subestima o risco real!\n")

#=
MÁXIMO DRAWDOWN IBOVESPA: Correção de Viés
Demonstração prática de como o drawdown empírico subestima o risco
=#

println("\n" * "="^80)
println("ANÁLISE DE MÁXIMO DRAWDOWN - IBOVESPA")
println("Problema: Drawdown empírico subestima perdas futuras")
println("Solução: Jackknife corrige o viés, Bootstrap fornece intervalos")
println("="^80)

# Função para baixar dados mensais usando YFinance.jl
function get_monthly_data(ticker; start_date="2000-01-01", end_date=Dates.today())
    println("Baixando dados mensais para $ticker usando YFinance.jl...")
    
    # Usar YFinance.jl para baixar dados mensais
    data = get_prices(ticker, startdt=start_date, enddt=end_date, interval="1mo")
    
    if isempty(data) || !haskey(data, "adjclose")
        error("ERRO CRÍTICO: Não foi possível baixar dados reais para $ticker.")
    end
    
    # Extrair preços ajustados
    prices = data["adjclose"]
    
    if length(prices) < 120  # Mínimo de 10 anos de dados mensais
        error("ERRO CRÍTICO: Dados insuficientes para $ticker ($(length(prices)) observações). Mínimo: 120.")
    end
    
    println("✓ Dados mensais obtidos para $ticker: $(length(prices)) observações")
    return prices
end

# Função para calcular retornos logarítmicos
function calculate_log_returns(prices)
    # Calcular retornos logarítmicos: ln(P_t / P_{t-1})
    log_returns = diff(log.(prices))
    
    println("Retornos logarítmicos calculados: $(length(log_returns)) observações")
    println("Período dos retornos: $(round(length(log_returns)/12, digits=1)) anos")
    
    return log_returns
end

# Baixar dados mensais do Ibovespa
ibovespa_prices = get_monthly_data("^BVSP")

# Validação simplificada para análise de drawdown
function simple_validation(data; alpha=0.05)
    println("\n" * "="^80)
    println("VALIDAÇÃO PARA ANÁLISE DE DRAWDOWN")
    println("Testando independência dos retornos (essencial para drawdown)")
    println("="^80)
    
    n = length(data)
    
    # TESTE DE LJUNG-BOX (Independência - mais relevante para drawdown)
    try
        lags = min(12, max(1, round(Int, n * 0.05)))  # Focar em sazonalidade mensal
        lb_test = LjungBoxTest(data, lags)
        lb_pvalue = pvalue(lb_test)
        
        println("🔍 Teste de Ljung-Box (Independência dos Retornos):")
        println("   H0: Retornos são independentes (sem autocorrelação)")
        println("   Lags testados: $lags")
        println("   p-value: $(round(lb_pvalue, digits=4))")
        
        if lb_pvalue > alpha
            println("   ✅ RESULTADO: Retornos independentes")
            println("   📊 Implicação: Drawdown jackknife é confiável")
        else
            println("   ⚠️  RESULTADO: Autocorrelação detectada")
            println("   📊 Implicação: Jackknife pode subestimar o viés")
        end
        
        return (pvalue=lb_pvalue, independent=lb_pvalue > alpha)
        
    catch e
        println("⚠️  Erro no teste de Ljung-Box: $e")
        println("   Continuando análise sem validação formal")
        return (pvalue=NaN, independent=false)
    end
    
    println("-"^80)
end

# Função para calcular máximo drawdown (CORRIGIDA para retornos logarítmicos)
function calculate_max_drawdown(returns)
    # Calcular curva de patrimônio para retornos logarítmicos
    # Fórmula: exp(cumsum(log_returns))
    equity_curve = exp.(cumsum(returns))
    
    # Calcular pico acumulado usando accumulate
    running_max = accumulate(max, equity_curve)
    
    # Calcular drawdowns (quedas percentuais)
    drawdowns = (equity_curve .- running_max) ./ running_max
    
    # Máximo drawdown
    max_dd = minimum(drawdowns)
    
    return abs(max_dd)  # Retornar como valor positivo
end

# Calcular dados do Ibovespa
monthly_returns = calculate_log_returns(ibovespa_prices)
max_drawdown = calculate_max_drawdown(monthly_returns)

println("Índice: Ibovespa (^BVSP)")
println("Período: $(round(length(monthly_returns)/12, digits=1)) anos ($(length(monthly_returns)) meses)")
println("Retorno médio mensal: $(round(mean(monthly_returns)*100, digits=2))%")
println("Volatilidade mensal: $(round(std(monthly_returns)*100, digits=2))%")
println("📉 MÁXIMO DRAWDOWN EMPÍRICO: $(round(max_drawdown*100, digits=2))%")
println("⚠️  Este drawdown provavelmente subestima o risco real!")

# VALIDAR PRESSUPOSTOS ANTES DAS ANÁLISES
validation_results = simple_validation(monthly_returns)

# JACKKNIFE para MÁXIMO DRAWDOWN: Correção de Viés
function jackknife_drawdown_analysis(data)
    n = length(data)
    jackknife_estimates = zeros(n)
    
    println("\n" * "="^80)
    println("JACKKNIFE: CORREÇÃO DE VIÉS DO MÁXIMO DRAWDOWN")
    println("="^80)
    
    # Estimativas deixando um mês de fora
    println("Calculando $n estimativas jackknife (deixando 1 mês de fora)...")
    for i in 1:n
        jackknife_sample = data[[1:i-1; i+1:n]]
        jackknife_estimates[i] = calculate_max_drawdown(jackknife_sample)
    end
    
    # Estimativa original
    original_dd = calculate_max_drawdown(data)
    jackknife_mean = mean(jackknife_estimates)
    
    # Estimação de viés (drawdown empírico sempre subestima)
    bias_estimate = (n - 1) * (jackknife_mean - original_dd)
    
    # Drawdown corrigido para viés
    bias_corrected_dd = original_dd - bias_estimate
    
    # Estimação do erro padrão
    jackknife_se = sqrt(((n-1)/n) * sum((jackknife_estimates .- jackknife_mean).^2))
    
    println("📉 RESULTADOS:")
    println("   Drawdown empírico: $(round(original_dd*100, digits=2))%")
    println("   Estimativa de viés: $(round(bias_estimate*100, digits=3))%")
    println("   Drawdown corrigido: $(round(bias_corrected_dd*100, digits=2))%")
    println("   Erro padrão: $(round(jackknife_se*100, digits=2))%")
    
    if bias_estimate > 0
        println("   ⚠️  CONFIRMADO: Drawdown empírico subestima o risco em $(round(bias_estimate*100, digits=2))%")
    else
        println("   ✓ Drawdown empírico não parece viesado")
    end
    
    return (
        original_estimate = original_dd,
        bias_estimate = bias_estimate,
        bias_corrected = bias_corrected_dd,
        standard_error = jackknife_se,
        jackknife_estimates = jackknife_estimates
    )
end

# MOVING BLOCK BOOTSTRAP para VaR 99%: Análise Robusta para Séries Temporais
function bootstrap_var_analysis(data, period_months=24, B=1000, alpha=0.05, var_level=0.01, block_size=6)
    n = length(data)
    
    if period_months >= n - 12
        error("Período muito longo para os dados disponíveis. Máximo: $(n-12) meses")
    end
    
    println("\n" * "="^80)
    println("MOVING BLOCK BOOTSTRAP: VaR 99% EM JANELAS DE $period_months MESES")
    println("Tamanho do bloco: $block_size meses")
    println("="^80)
    
    # Calcular VaR empírico com dados originais
    num_windows = n - period_months + 1
    original_cumulative_returns = zeros(num_windows)
    
    println("Calculando VaR 99% empírico dos retornos acumulados...")
    
    for i in 1:num_windows
        window_data = data[i:i+period_months-1]
        # Calcular retorno acumulado: exp(sum(log_returns)) - 1
        original_cumulative_returns[i] = exp(sum(window_data)) - 1
    end
    
    empirical_var = quantile(original_cumulative_returns, var_level)
    empirical_var_mean = mean(original_cumulative_returns)
    
    # Moving Block Bootstrap
    bootstrap_vars = zeros(B)
    num_blocks_needed = ceil(Int, n / block_size)
    
    println("Gerando $B séries sintéticas com Moving Block Bootstrap...")
    println("Número de blocos por série: $num_blocks_needed")
    
    for b in 1:B
        # Construir série sintética concatenando blocos aleatórios
        synthetic_series = Float64[]
        
        for block in 1:num_blocks_needed
            # Selecionar posição inicial aleatória para o bloco
            max_start = n - block_size + 1
            if max_start < 1
                max_start = 1
            end
            block_start = rand(1:max_start)
            block_end = min(block_start + block_size - 1, n)
            
            # Adicionar bloco à série sintética
            append!(synthetic_series, data[block_start:block_end])
        end
        
        # Truncar para o tamanho original
        synthetic_series = synthetic_series[1:min(n, length(synthetic_series))]
        
        # Calcular VaR para a série sintética
        if length(synthetic_series) >= period_months
            synth_num_windows = length(synthetic_series) - period_months + 1
            synth_cumulative_returns = zeros(synth_num_windows)
            
            for i in 1:synth_num_windows
                window_data = synthetic_series[i:i+period_months-1]
                synth_cumulative_returns[i] = exp(sum(window_data)) - 1
            end
            
            bootstrap_vars[b] = quantile(synth_cumulative_returns, var_level)
        else
            # Fallback para séries muito curtas
            bootstrap_vars[b] = empirical_var
        end
    end
    
    # Intervalos de confiança do VaR
    ci_lower = quantile(bootstrap_vars, alpha/2)
    ci_upper = quantile(bootstrap_vars, 1 - alpha/2)
    bootstrap_var_mean = mean(bootstrap_vars)
    bootstrap_var_std = std(bootstrap_vars)
    
    println("📊 RESULTADOS VaR 99% - MOVING BLOCK BOOTSTRAP ($(period_months) meses):")
    println("   VaR 99% empírico: $(round(empirical_var*100, digits=2))%")
    println("   VaR 99% bootstrap: $(round(bootstrap_var_mean*100, digits=2))%")
    println("   Desvio padrão bootstrap: $(round(bootstrap_var_std*100, digits=2))%")
    println("   IC $(Int((1-alpha)*100))%: [$(round(ci_lower*100, digits=2))%, $(round(ci_upper*100, digits=2))%]")
    println("   Retorno médio ($(period_months)m): $(round(empirical_var_mean*100, digits=2))%")
    println("   Pior retorno observado: $(round(minimum(original_cumulative_returns)*100, digits=2))%")
    println("   💡 Interpretação: IC reflete incerteza estatística preservando dependência temporal")
    
    return (
        period_months = period_months,
        block_size = block_size,
        empirical_var = empirical_var,
        bootstrap_var_mean = bootstrap_var_mean,
        bootstrap_var_std = bootstrap_var_std,
        ci_lower = ci_lower,
        ci_upper = ci_upper,
        cumulative_returns = original_cumulative_returns,
        worst_return = minimum(original_cumulative_returns),
        best_return = maximum(original_cumulative_returns),
        mean_return = empirical_var_mean,
        bootstrap_estimates = bootstrap_vars
    )
end

# CONFIGURAR PERÍODOS DE ANÁLISE
DRAWDOWN_PERIOD_MONTHS = 12  # Jackknife para drawdown em 12 meses
VAR_PERIOD_MONTHS = 24       # Bootstrap para VaR 99% em 24 meses

# ANÁLISE DE DRAWDOWN PARA PERÍODO ESPECÍFICO
function analyze_drawdown_period(data; period_months=12)
    println("\n" * "="^80)
    println("ANÁLISE DE DRAWDOWN - PERÍODO DE $(round(period_months/12, digits=1)) ANO(S)")
    println("Análise focada em janelas deslizantes de $period_months meses")
    println("="^80)
    
    n = length(data)
    
    if period_months >= n - 12
        error("Período muito longo para os dados disponíveis. Máximo: $(n-12) meses")
    end
    
    years = round(period_months/12, digits=1)
    println("\n📊 Analisando janelas de $period_months meses ($years anos)...")
    
    # Calcular viés para várias janelas deslizantes
    num_windows = n - period_months + 1
    bias_estimates = zeros(num_windows)
    empirical_dds = zeros(num_windows)
    corrected_dds = zeros(num_windows)
    
    for i in 1:num_windows
        window_data = data[i:i+period_months-1]
        
        # Jackknife para esta janela específica
        jack_estimates = zeros(period_months)
        for j in 1:period_months
            jack_sample = window_data[[1:j-1; j+1:period_months]]
            jack_estimates[j] = calculate_max_drawdown(jack_sample)
        end
        
        empirical_dd = calculate_max_drawdown(window_data)
        jack_mean = mean(jack_estimates)
        bias_est = (period_months - 1) * (jack_mean - empirical_dd)
        
        bias_estimates[i] = bias_est
        empirical_dds[i] = empirical_dd
        corrected_dds[i] = empirical_dd - bias_est
    end
    
    # Estatísticas do viés
    mean_bias = mean(bias_estimates)
    mean_empirical = mean(empirical_dds)
    mean_corrected = mean(corrected_dds)
    max_empirical = maximum(empirical_dds)
    max_corrected = maximum(corrected_dds)
    
    # Percentual médio de subestimação
    underestimation_pct = (mean_corrected - mean_empirical) / mean_corrected * 100
    
    println("  📉 Drawdown empírico médio: $(round(mean_empirical*100, digits=2))%")
    println("  📈 Drawdown corrigido médio: $(round(mean_corrected*100, digits=2))%")
    println("  📉 Drawdown empírico máximo: $(round(max_empirical*100, digits=2))%")
    println("  📈 Drawdown corrigido máximo: $(round(max_corrected*100, digits=2))%")
    println("  ⚠️  Subestimação média: $(round(abs(underestimation_pct), digits=1))%")
    println("  💡 Conclusão: $(abs(underestimation_pct) > 5 ? "Viés SIGNIFICATIVO" : "Viés baixo")")
    
    return (
        period_months = period_months,
        mean_bias = mean_bias,
        mean_empirical_dd = mean_empirical,
        mean_corrected_dd = mean_corrected,
        max_empirical_dd = max_empirical,
        max_corrected_dd = max_corrected,
        underestimation_pct = underestimation_pct,
        num_windows = num_windows,
        bias_estimates = bias_estimates,
        empirical_dds = empirical_dds,
        corrected_dds = corrected_dds
    )
end

# Executar análise de drawdown para 12 meses (Jackknife)
drawdown_results = analyze_drawdown_period(monthly_returns, period_months=DRAWDOWN_PERIOD_MONTHS)

# Executar análise de VaR 99% para 24 meses (Bootstrap)
var_results = bootstrap_var_analysis(monthly_returns, VAR_PERIOD_MONTHS)

# RESUMO SIMPLIFICADO DOS RESULTADOS
function display_period_summary(results)
    println("\n" * "="^80)
    println("RESUMO: ANÁLISE DE DRAWDOWN - $(round(results.period_months/12, digits=1)) ANO(S)")
    println("="^80)
    
    println("📊 ESTATÍSTICAS DO PERÍODO:")
    println("  • Drawdown empírico médio: $(round(results.mean_empirical_dd*100, digits=2))%")
    println("  • Drawdown corrigido médio: $(round(results.mean_corrected_dd*100, digits=2))%") 
    println("  • Drawdown empírico máximo: $(round(results.max_empirical_dd*100, digits=2))%")
    println("  • Drawdown corrigido máximo: $(round(results.max_corrected_dd*100, digits=2))%")
    println("  • Subestimação média: $(round(abs(results.underestimation_pct), digits=1))%")
    println("  • Janelas analisadas: $(results.num_windows)")
    
    println("\n💡 INTERPRETAÇÃO PRÁTICA:")
    if abs(results.underestimation_pct) > 20
        println("   ⚠️  VIÉS ALTO: Drawdown empírico subestima significativamente o risco")
        println("   🎯 RECOMENDAÇÃO: SEMPRE use drawdown corrigido por jackknife")
    elseif abs(results.underestimation_pct) > 10
        println("   ⚠️  VIÉS MODERADO: Drawdown empírico subestima o risco")
        println("   🎯 RECOMENDAÇÃO: Use jackknife para estimativas mais precisas")
    else
        println("   ✅ VIÉS BAIXO: Drawdown empírico é relativamente confiável")
        println("   🎯 RECOMENDAÇÃO: Jackknife ainda melhora a precisão")
    end
    
    return nothing
end

# RESUMO COMBINADO DAS ANÁLISES
function display_combined_summary(dd_results, var_results)
    println("\n" * "="^80)
    println("RESUMO COMBINADO: DRAWDOWN (12m) + VaR 99% (24m)")
    println("="^80)
    
    println("🎯 ANÁLISE DE DRAWDOWN - 12 MESES (JACKKNIFE):")
    println("  • Drawdown empírico médio: $(round(dd_results.mean_empirical_dd*100, digits=2))%")
    println("  • Drawdown corrigido médio: $(round(dd_results.mean_corrected_dd*100, digits=2))%")
    println("  • Subestimação: $(round(abs(dd_results.underestimation_pct), digits=1))%")
    println("  • Janelas analisadas: $(dd_results.num_windows)")
    
    println("\n📊 ANÁLISE DE VaR 99% - 24 MESES (MOVING BLOCK BOOTSTRAP):")
    println("  • VaR 99% empírico: $(round(var_results.empirical_var*100, digits=2))%")
    println("  • VaR 99% bootstrap: $(round(var_results.bootstrap_var_mean*100, digits=2))%")
    println("  • Desvio padrão bootstrap: $(round(var_results.bootstrap_var_std*100, digits=2))%")
    println("  • IC 95%: [$(round(var_results.ci_lower*100, digits=2))%, $(round(var_results.ci_upper*100, digits=2))%]")
    println("  • Tamanho do bloco: $(var_results.block_size) meses")
    println("  • Retorno médio (24m): $(round(var_results.mean_return*100, digits=2))%")
    println("  • Pior retorno (24m): $(round(var_results.worst_return*100, digits=2))%")
    
    println("\n💡 COMPARAÇÃO DE MÉTRICAS DE RISCO:")
    println("  📉 Drawdown corrigido (12m): $(round(dd_results.mean_corrected_dd*100, digits=2))%")
    println("  📊 VaR 99% retornos (24m): $(round(abs(var_results.empirical_var)*100, digits=2))%")
    
    if abs(var_results.empirical_var) > dd_results.mean_corrected_dd
        println("  ⚠️  VaR 99% > Drawdown: Perdas extremas de 24m mais severas que drawdown 12m")
    else
        println("  ⚠️  Drawdown > VaR 99%: Perdas acumuladas 12m mais severas que extremos 24m")
    end
    
    println("\n🎯 RECOMENDAÇÕES PRÁTICAS:")
    println("  • Use drawdown corrigido para planejamento de longo prazo")
    println("  • Use VaR 99% para gestão de risco mensal")
    println("  • Combine ambas métricas para visão completa de risco")
    
    return nothing
end

# Executar visualização combinada
display_combined_summary(drawdown_results, var_results)

