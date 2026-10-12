# # Задача об эпидемии (SIR-модель с порогом)
#
# **Вариант 38:**
# N = 12700, I(0) = 170, R(0) = 57, S(0) = N - I(0) - R(0) = 12473.
#
# Рассматриваются два случая: I(0) ≤ I* и I(0) > I*.

using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Параметры

N  = 12700.0
I0 = 170.0
R0 = 57.0
S0 = N - I0 - R0

α = 0.01   # коэффициент заболеваемости
β  = 0.02  # коэффициент выздоровления
I_star = 100.0  # критическое значение

tspan = (0.0, 200.0)
u0 = [S0, I0, R0]

# ## Случай A: I(0) ≤ I* — все больные изолированы
# dS/dt = 0, dI/dt = -βI, dR/dt = βI

function sir_caseA!(du, u, p, t)
    α, β = p
    S, I, R = u
    du[1] = 0.0
    du[2] = -β * I
    du[3] =  β * I
end

probA = ODEProblem(sir_caseA!, u0, tspan, [α, β])
solA = solve(probA, Tsit5(), saveat=0.1)

# ## Случай B: I(0) > I* — эпидемия развивается
# dS/dt = -αS, dI/dt = αS - βI, dR/dt = βI

function sir_caseB!(du, u, p, t)
    α, β = p
    S, I, R = u
    du[1] = -α * S
    du[2] =  α * S - β * I
    du[3] =  β * I
end

probB = ODEProblem(sir_caseB!, u0, tspan, [α, β])
solB = solve(probB, Tsit5(), saveat=0.1)

# ## Анализ

println("=== Вариант 38 ===")
println("N = ", N, ", I(0) = ", I0, ", R(0) = ", R0, ", S(0) = ", S0)
println("α = ", α, ", β = ", β, ", I* = ", I_star)
println()
println("Случай A (I(0) ≤ I*):")
println("  I(200) = ", round(last(solA.u)[2], digits=2))
println("  R(200) = ", round(last(solA.u)[3], digits=2))
println()
println("Случай B (I(0) > I*):")
println("  S(200) = ", round(last(solB.u)[1], digits=2))
println("  I(200) = ", round(last(solB.u)[2], digits=2))
println("  R(200) = ", round(last(solB.u)[3], digits=2))

# ## Графики

# Случай A
pA = plot(solA, label=["S(t)" "I(t)" "R(t)"],
          title="Случай A: I(0) ≤ I*",
          xlabel="t", ylabel="Численность", lw=2)
savefig(plotsdir(script_name, "caseA.png"))

# Случай B
pB = plot(solB, label=["S(t)" "I(t)" "R(t)"],
          title="Случай B: I(0) > I*",
          xlabel="t", ylabel="Численность", lw=2)
savefig(plotsdir(script_name, "caseB.png"))

# Сводный график
pall = plot(pA, pB, layout=(2,1), size=(900, 800))
savefig(plotsdir(script_name, "cases_all.png"))

# ## Сохранение

dfA = DataFrame(t=solA.t, S=first.(solA.u), I=[u[2] for u in solA.u], R=last.(solA.u))
dfB = DataFrame(t=solB.t, S=first.(solB.u), I=[u[2] for u in solB.u], R=last.(solB.u))

@save datadir(script_name, "epidemic_results.jld2") dfA dfB solA solB

println("\nСохранено в plots/$(script_name)/ и data/$(script_name)/")