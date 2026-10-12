# # Модели Ланчестера (модели боевых действий)
#
# **Цель:** исследовать три модели боя между странами X и Y.
#
# ## Модели
#
# 1. **Регулярные войска против регулярных:**
#    $$\frac{dx}{dt} = -ax - by + P(t), \quad \frac{dy}{dt} = -cx - hy + Q(t)$$
#
# 2. **Регулярные войска против партизан:**
#    $$\frac{dx}{dt} = -ax - by + P(t), \quad \frac{dy}{dt} = -cxy - hy + Q(t)$$
#
# 3. **Партизаны против партизан:**
#    $$\frac{dx}{dt} = -ax - bxy + P(t), \quad \frac{dy}{dt} = -cxy - hy + Q(t)$$

using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Параметры модели

a = 0.4        # потери X, не связанные с боями
b = 0.8        # эффективность Y против X
c = 0.5        # эффективность X против Y
h = 0.7        # потери Y, не связанные с боями

x0 = 20000.0   # начальная численность X
y0 = 9000.0    # начальная численность Y

tspan = (0.0, 1.0)

# ## Функции подкрепления

P(t) = sin(t) + 1
Q(t) = cos(t) + 1

# ## Модель 1: регулярные vs регулярные

function battle1!(du, u, p, t)
    a, b, c, h = p
    x, y = u
    du[1] = -a*x - b*y + P(t)
    du[2] = -c*x - h*y + Q(t)
end

# ## Модель 2: регулярные vs партизаны

function battle2!(du, u, p, t)
    a, b, c, h = p
    x, y = u
    du[1] = -a*x - b*y + P(t)
    du[2] = -c*x*y - h*y + Q(t)
end

# ## Модель 3: партизаны vs партизаны

function battle3!(du, u, p, t)
    a, b, c, h = p
    x, y = u
    du[1] = -a*x - b*x*y + P(t)
    du[2] = -c*x*y - h*y + Q(t)
end

# ## Численное решение

u0 = [x0, y0]
params = [a, b, c, h]

prob1 = ODEProblem(battle1!, u0, tspan, params)
prob2 = ODEProblem(battle2!, u0, tspan, params)
prob3 = ODEProblem(battle3!, u0, tspan, params)

sol1 = solve(prob1, Tsit5(), saveat=0.01)
sol2 = solve(prob2, Tsit5(), saveat=0.01)
sol3 = solve(prob3, Tsit5(), saveat=0.01)

# ## Анализ победителя

function winner(sol)
    x_final = last(sol.u)[1]
    y_final = last(sol.u)[2]
    if x_final > y_final
        return "X (победа по остатку)"
    elseif y_final > x_final
        return "Y (победа по остатку)"
    else
        return "ничья"
    end
end

println("=== Результаты ===")
println("Модель 1 (рег vs рег):  X = ", round(last(sol1.u)[1], digits=1),
        ", Y = ", round(last(sol1.u)[2], digits=1), " → ", winner(sol1))
println("Модель 2 (рег vs парт): X = ", round(last(sol2.u)[1], digits=1),
        ", Y = ", round(last(sol2.u)[2], digits=1), " → ", winner(sol2))
println("Модель 3 (парт vs парт): X = ", round(last(sol3.u)[1], digits=1),
        ", Y = ", round(last(sol3.u)[2], digits=1), " → ", winner(sol3))

# ## Визуализация

# Общий график всех трёх моделей на одном поле
p1 = plot(sol1, label=["X" "Y"],
          title="Модель 1: регулярные vs регулярные",
          xlabel="Время", ylabel="Численность",
          lw=2, legend=:topright)
savefig(plotsdir(script_name, "battle1.png"))

p2 = plot(sol2, label=["X" "Y"],
          title="Модель 2: регулярные vs партизаны",
          xlabel="Время", ylabel="Численность",
          lw=2, legend=:topright)
savefig(plotsdir(script_name, "battle2.png"))

p3 = plot(sol3, label=["X" "Y"],
          title="Модель 3: партизаны vs партизаны",
          xlabel="Время", ylabel="Численность",
          lw=2, legend=:topright)
savefig(plotsdir(script_name, "battle3.png"))

# Сводный график
pall = plot(p1, p2, p3, layout=(3,1), size=(900, 1000))
savefig(plotsdir(script_name, "battles_all.png"))

# ## Сохранение результатов

df = DataFrame(
    t = sol1.t,
    x1 = first.(sol1.u), y1 = last.(sol1.u),
    x2 = first.(sol2.u), y2 = last.(sol2.u),
    x3 = first.(sol3.u), y3 = last.(sol3.u)
)

@save datadir(script_name, "lanchester_results.jld2") df sol1 sol2 sol3

println("\nСохранено:")
println("  plots/$(script_name)/")
println("  data/$(script_name)/lanchester_results.jld2")