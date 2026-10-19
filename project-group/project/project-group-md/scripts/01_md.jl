using DrWatson
@quickactivate "project-group-md"
using Plots
using Statistics
using JLD2
script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))
N = 64
L = 10.0
eps_lj = 1.0
b_lj = 1.0
rc = 2.5 * b_lj
dt = 0.0005
Nsteps = 10000
n_side = round(Int, sqrt(N))
coords0 = [ (i-1)*L/n_side + L/(2*n_side) for i in 1:n_side ]
r0 = [ (x, y) for x in coords0 for y in coords0 ]
r = [ [r0[i][1] + 0.01*randn(), r0[i][2] + 0.01*randn()] for i in 1:N ]
v = [ [randn(), randn()] for i in 1:N ]
v_sum = sum(v)
v = [ [v[i][1] - v_sum[1]/N, v[i][2] - v_sum[2]/N] for i in 1:N ]
# Потенциал с минимумом при r = b = 1
function lj_force(r_ij)
    r_norm = sqrt(r_ij[1]^2 + r_ij[2]^2)
    if r_norm > rc || r_norm < 1e-12
        return [0.0, 0.0], 0.0
    end
    # Сдвигаем, чтобы избежать сингулярности
    r_min = 0.9
    rr = max(r_norm, r_min)
    inv_r2 = 1.0 / rr^2
    inv_r6 = inv_r2^3
    inv_r12 = inv_r6^2
    f_mag = 24 * eps_lj * (2*inv_r12 - inv_r6) * inv_r2
    u = 4 * eps_lj * (inv_r12 - inv_r6)
    # Ограничим силу
    f_max = 200.0
    if f_mag > f_max
        f_mag = f_max
    end
    return [f_mag * r_ij[1], f_mag * r_ij[2]], u
end
function compute_forces(r)
    Nloc = length(r)
    f = [ [0.0, 0.0] for _ in 1:Nloc ]
    U = 0.0
    for i in 1:Nloc-1
        for j in i+1:Nloc
            r_ij = [r[i][1] - r[j][1], r[i][2] - r[j][2]]
            f_ij, u_ij = lj_force(r_ij)
            f[i][1] += f_ij[1]; f[i][2] += f_ij[2]
            f[j][1] -= f_ij[1]; f[j][2] -= f_ij[2]
            U += u_ij
        end
    end
    return f, U
end
function total_energy(r, v)
    f, U = compute_forces(r)
    K = sum(0.5 * (v[i][1]^2 + v[i][2]^2) for i in 1:length(v))
    return K + U, K, U
end
f, _ = compute_forces(r)
E0, _, _ = total_energy(r, v)
snapshots_r = []
snapshots_t = Float64[]
energies_K = Float64[]
energies_U = Float64[]
energies_E = Float64[]
push!(snapshots_r, deepcopy(r))
push!(snapshots_t, 0.0)
push!(energies_K, 0.0); push!(energies_U, 0.0); push!(energies_E, E0)
for step in 1:Nsteps
    global r, v, f
    v_half = [ [v[i][1] + f[i][1]*dt/2, v[i][2] + f[i][2]*dt/2] for i in 1:N ]
    r_new = [ [r[i][1] + v_half[i][1]*dt, r[i][2] + v_half[i][2]*dt] for i in 1:N ]
    # БЕЗ периодических границ — кластер в свободном пространстве
    f_new, _ = compute_forces(r_new)
    v_new = [ [v_half[i][1] + f_new[i][1]*dt/2, v_half[i][2] + f_new[i][2]*dt/2] for i in 1:N ]
    r = r_new; v = v_new; f = f_new
    if step % 200 == 0
        E, K, U = total_energy(r, v)
        push!(snapshots_r, deepcopy(r))
        push!(snapshots_t, step*dt)
        push!(energies_K, K); push!(energies_U, U); push!(energies_E, E)
    end
end
println("Полная энергия: E0 = ", round(E0, digits=4), ", E_end = ", round(energies_E[end], digits=4))
println("Относительное отклонение: ", round((energies_E[end]-E0)/abs(E0) * 100, digits=4), " %")
p1 = plot(xlabel="x", ylabel="y", title="Частицы", aspect_ratio=:equal, legend=false)
for pp in snapshots_r[end]
    scatter!(p1, [pp[1]], [pp[2]], markersize=6, color=:blue)
end
savefig(plotsdir(script_name, "snapshot.png"))
p2 = plot(snapshots_t, energies_K, label="K", lw=2, xlabel="t", ylabel="E", title="Кинетическая")
savefig(plotsdir(script_name, "kinetic.png"))
p3 = plot(snapshots_t, energies_U, label="U", lw=2, xlabel="t", ylabel="E", title="Потенциальная")
savefig(plotsdir(script_name, "potential.png"))
p4 = plot(snapshots_t, energies_E, label="E", lw=2, xlabel="t", ylabel="E", title="Полная")
savefig(plotsdir(script_name, "total.png"))
pall = plot(p1, p2, p3, p4, layout=(2,2), size=(1000, 800))
savefig(plotsdir(script_name, "all.png"))
@save datadir(script_name, "md_results.jld2") snapshots_r snapshots_t energies_K energies_U energies_E
println("Сохранено.")