using DrWatson
@quickactivate "project-group-md"
using Plots
using JLD2
script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))
N = 32
m = 1.0
k = 1.0
omega0 = sqrt(k/m)
dt = 0.01
Nsteps = 5000
harmonics = [1, 2, 3]
p_all = plot(size=(900, 800), layout=(3,1))
for (idx, l) in enumerate(harmonics)
    y = [sin(l*pi*i/(N+1)) for i in 1:N]
    v = zeros(N)
    t_snap = Float64[]
    y_snap = Vector{Vector{Float64}}()
    push!(t_snap, 0.0)
    push!(y_snap, copy(y))
    for step in 1:Nsteps
        a = [k*(y[i+1] - 2y[i] + y[i-1])/m for i in 2:N-1]
        a = vcat(k*(y[2] - 2y[1])/m, a, k*(y[N-1] - 2y[N])/m)
        v_half = v + a*dt/2
        y_new = y + v_half*dt
        a_new = [k*(y_new[i+1] - 2y_new[i] + y_new[i-1])/m for i in 2:N-1]
        a_new = vcat(k*(y_new[2] - 2y_new[1])/m, a_new, k*(y_new[N-1] - 2y_new[N])/m)
        v_new = v_half + a_new*dt/2
        y = y_new
        v = v_new
        if step % 100 == 0
            push!(t_snap, step*dt)
            push!(y_snap, copy(y))
        end
    end
    for (j, (t, ys)) in enumerate(zip(t_snap, y_snap))
        if j % 10 == 1
            plot!(p_all[idx], 1:N, ys, label="t=$(round(t, digits=2))", lw=2, alpha=0.5)
        end
    end
    plot!(p_all[idx], title="Гармоника l = $l", ylabel="y_i", xlabel="i")
end
savefig(plotsdir(script_name, "harmonics.png"))
println("Аналитические частоты:")
for l in harmonics
    omega_l = 2*omega0*sin(l*pi/(2*(N+1)))
    println("  l=$l: ω_l = ", round(omega_l, digits=4))
end
println("Сохранено.")