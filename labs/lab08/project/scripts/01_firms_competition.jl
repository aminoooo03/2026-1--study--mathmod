# # Модель конкуренции двух фирм
# **Вариант 38.**

using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

p_cr = 25.0
N = 39.0
q = 1.0
tau1 = 29.0
tau2 = 19.0
p1 = 6.9
p2 = 15.9

a1 = p_cr / (tau1^2 * p1^2 * N * q)
a2 = p_cr / (tau2^2 * p2^2 * N * q)
b  = p_cr / (tau1^2 * p1^2 * tau2^2 * p2^2 * N * q)
c1 = (p_cr - p1) / (tau1 * p1)
c2 = (p_cr - p2) / (tau2 * p2)

println("Коэффициенты:")
println("  a1 = ", round(a1, digits=6))
println("  a2 = ", round(a2, digits=6))
println("  b  = ", round(b, digits=8))
println("  c1 = ", round(c1, digits=6))
println("  c2 = ", round(c2, digits=6))

function sys1!(du, u, p, theta)
    M1, M2 = u
    du[1] = M1 - (b/c1) * M1 * M2 - (a1/c1) * M1^2
    du[2] = (c2/c1) * M2 - (b/c1) * M1 * M2 - (a2/c1) * M2^2
end

u0 = [3.9, 2.9]
thetspan = (0.0, 30.0)

prob1 = ODEProblem(sys1!, u0, thetspan)
sol1 = solve(prob1, Tsit5(), saveat=0.05)

function sys2!(du, u, p, theta)
    M1, M2 = u
    du[1] = M1 - (b/c1 + 0.00083) * M1 * M2 - (a1/c1) * M1^2
    du[2] = (c2/c1) * M2 - (b/c1) * M1 * M2 - (a2/c1) * M2^2
end

prob2 = ODEProblem(sys2!, u0, thetspan)
sol2 = solve(prob2, Tsit5(), saveat=0.05)

println("\n=== Случай 1 ===")
println("M1(30) = ", round(last(sol1.u)[1], digits=4))
println("M2(30) = ", round(last(sol1.u)[2], digits=4))

println("\n=== Случай 2 ===")
println("M1(30) = ", round(last(sol2.u)[1], digits=4))
println("M2(30) = ", round(last(sol2.u)[2], digits=4))

pA = plot(sol1, label=["M1" "M2"],
          title="Случай 1",
          xlabel="theta", ylabel="M", lw=2)
savefig(plotsdir(script_name, "case1.png"))

pB = plot(sol2, label=["M1" "M2"],
          title="Случай 2",
          xlabel="theta", ylabel="M", lw=2)
savefig(plotsdir(script_name, "case2.png"))

pall = plot(pA, pB, layout=(2,1), size=(900, 800))
savefig(plotsdir(script_name, "cases_all.png"))

df1 = DataFrame(theta=sol1.t, M1=first.(sol1.u), M2=last.(sol1.u))
df2 = DataFrame(theta=sol2.t, M1=first.(sol2.u), M2=last.(sol2.u))

@save datadir(script_name, "firms_competition_results.jld2") df1 df2 sol1 sol2

println("\nСохранено.")