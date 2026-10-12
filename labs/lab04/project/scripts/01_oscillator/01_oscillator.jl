using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

x0 = 1.2
y0 = -1.2
tspan = (0.0, 72.0)
u0 = [x0, y0]

function osc1!(du, u, p, t)
    x, y = u
    du[1] = y
    du[2] = -21.0 * x
end

prob1 = ODEProblem(osc1!, u0, tspan)
sol1 = solve(prob1, Tsit5(), saveat=0.05)

function osc2!(du, u, p, t)
    x, y = u
    du[1] = y
    du[2] = -2.2 * y - 2.3 * x
end

prob2 = ODEProblem(osc2!, u0, tspan)
sol2 = solve(prob2, Tsit5(), saveat=0.05)

function osc3!(du, u, p, t)
    x, y = u
    du[1] = y
    du[2] = -2.4 * y - 2.5 * x + 0.2 * sin(2.6 * t)
end

prob3 = ODEProblem(osc3!, u0, tspan)
sol3 = solve(prob3, Tsit5(), saveat=0.05)

p1 = plot(sol1, idxs=1, label="x(t)",
          title="Случай 1: без затухания",
          xlabel="t", ylabel="x", lw=2)
savefig(plotsdir(script_name, "solution1.png"))

p2 = plot(sol2, idxs=1, label="x(t)",
          title="Случай 2: с затуханием",
          xlabel="t", ylabel="x", lw=2)
savefig(plotsdir(script_name, "solution2.png"))

p3 = plot(sol3, idxs=1, label="x(t)",
          title="Случай 3: с затуханием и внешней силой",
          xlabel="t", ylabel="x", lw=2)
savefig(plotsdir(script_name, "solution3.png"))

ph1 = plot(first.(sol1.u), last.(sol1.u),
           title="Фазовый портрет 1",
           xlabel="x", ylabel="ẋ", lw=2, color=:blue)
savefig(plotsdir(script_name, "phase1.png"))

ph2 = plot(first.(sol2.u), last.(sol2.u),
           title="Фазовый портрет 2 (затухание)",
           xlabel="x", ylabel="ẋ", lw=2, color=:red)
savefig(plotsdir(script_name, "phase2.png"))

ph3 = plot(first.(sol3.u), last.(sol3.u),
           title="Фазовый портрет 3 (внешняя сила)",
           xlabel="x", ylabel="ẋ", lw=2, color=:green)
savefig(plotsdir(script_name, "phase3.png"))

pall = plot(p1, p2, p3, ph1, ph2, ph3,
            layout=(2, 3), size=(1400, 800))
savefig(plotsdir(script_name, "all_plots.png"))

println("=== Вариант 38 ===")
println("x0 = ", x0, ", y0 = ", y0)
println("t ∈ [0; ", tspan[2], "]")
println()
println("Случай 1 (без затухания):  x(72) = ", round(last(sol1.u)[1], digits=3))
println("Случай 2 (с затуханием):   x(72) = ", round(last(sol2.u)[1], digits=6))
println("Случай 3 (с внешней силой): x(72) = ", round(last(sol3.u)[1], digits=6))

df1 = DataFrame(t=sol1.t, x=first.(sol1.u), dx=last.(sol1.u))
df2 = DataFrame(t=sol2.t, x=first.(sol2.u), dx=last.(sol2.u))
df3 = DataFrame(t=sol3.t, x=first.(sol3.u), dx=last.(sol3.u))

@save datadir(script_name, "oscillator_results.jld2") df1 df2 df3 sol1 sol2 sol3

println("\nСохранено в plots/$(script_name)/ и data/$(script_name)/")
