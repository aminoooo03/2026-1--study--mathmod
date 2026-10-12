using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

x0 = 882000.0
y0 = 747000.0
tspan = (0.0, 5.0)

function battle1!(du, u, p, t)
    x, y = u
    du[1] = -0.4*x - 0.67*y + sin(3t) + 1
    du[2] = -0.77*x - 0.14*y + cos(2t) + 2
end

function battle2!(du, u, p, t)
    x, y = u
    du[1] = -0.24*x - 0.67*y + abs(sin(2t))
    du[2] = -0.47*x*y - 0.14*y + abs(cos(2t))
end

u0 = [x0, y0]

prob1 = ODEProblem(battle1!, u0, tspan)
sol1 = solve(prob1, Tsit5(), saveat=0.05)

prob2 = ODEProblem(battle2!, u0, tspan)
sol2 = solve(prob2, Tsit5(), saveat=0.05)

println("=== Вариант 38 ===")
println("Начальные: X = ", x0, ", Y = ", y0)
println()
println("Модель 1 (рег vs рег):")
println("  X(5) = ", round(last(sol1.u)[1], digits=1))
println("  Y(5) = ", round(last(sol1.u)[2], digits=1))
println()
println("Модель 2 (рег vs парт):")
println("  X(5) = ", round(last(sol2.u)[1], digits=1))
println("  Y(5) = ", round(last(sol2.u)[2], digits=1))

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

pall = plot(p1, p2, layout=(2,1), size=(900, 800))
savefig(plotsdir(script_name, "battles_all.png"))

df1 = DataFrame(t=sol1.t, x=first.(sol1.u), y=last.(sol1.u))
df2 = DataFrame(t=sol2.t, x=first.(sol2.u), y=last.(sol2.u))

@save datadir(script_name, "lanchester_results.jld2") df1 df2 sol1 sol2

println("\nСохранено в plots/$(script_name)/ и data/$(script_name)/")
