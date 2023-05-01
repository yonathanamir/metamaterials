using Plots


function gen_tl_γ_Z₀(R, G, C, L)
    function _inner(ω)
        a₁ = (R+im*ω*L)
        a₂ = (G+im*ω*C)

        γ = sqrt(a₁*a₂)
        Z₀ = sqrt(a₁/a₂)

        return γ, Z₀
    end

    return _inner
end


function abcd_transmission_line(R, G, C, L, l)
    gamma_z_func = gen_tl_γ_Z₀(R, G, C, L)

    function _inner(ω)
        γ, Z = gamma_z_func(ω)
        # println("ω=$ω: γ=$γ, Z=$Z")

        return [
            cos(γ*l) im*Z*sin(γ*l);
            (im/Z)*sin(γ*l) cos(γ*l)
        ]
    end

    return _inner
end


function abcd_series_element(z_func)
    function _inner(ω)
        Z = z_func(ω)
        return [
            1 Z;
            0 1
        ]
    end

    return _inner
end


function abcd_shunt_element(z_func)
    function _inner(ω)
        Z = z_func(ω)
        return [
            1 0;
            1/Z 1
        ]
    end

    return _inner
end


function impedence_resistor(R)
    function _inner(ω)
        return R
    end

    return _inner
end


function impedence_capacitator(C)
    function _inner(ω)
        return 1/(im*ω*C)
    end

    return _inner
end


function impedence_inductor(L)
    function _inner(ω)
        return im*ω*L
    end

    return _inner
end


function abcd_clrh_cell(L₀, C₀, C, L, d)
    tl1 = abcd_transmission_line(0, 0, C₀, L₀, d/2)
    inductor = abcd_shunt_element(impedence_inductor(L))
    tl2 = abcd_transmission_line(0, 0, C₀, L₀, d/2)
    capacitator = abcd_series_element(impedence_capacitator(C))

    tl_l = abcd_series_element(impedence_inductor(L₀*d))
    tl_c = abcd_shunt_element(impedence_capacitator(C₀*d))

    # tl_complete = abcd_transmission_line(0, 0, C₀, L₀, d)

    function _inner(ω)
        tl1_ω = tl1(ω)
        inductor_ω = inductor(ω)
        tl2_ω = tl2(ω)
        capacitator_ω = capacitator(ω)
        tl_ω = tl_l(ω) * tl_c(ω) 

        # return tl1_ω * inductor_ω * inductor_ω * tl2_ω * capacitator_ω
        return tl_ω * inductor_ω * capacitator_ω
        
    end

    return _inner
end


function abcd_metamaterial_system(L₀, C₀, C, L, d, num_cells)
    function _inner(ω)
        sys = [1 0; 0 1]

        for _ in collect(1:num_cells)
            sys = sys * abcd_clrh_cell(L₀, C₀, C, L, d)(ω)
        end

        return sys
    end

    return _inner
end


function abcd_sim(ωs, L₀, C₀, C, L, d, num_cells, jumps_per_cell)
    v_end = [1, 1/50]

    vs = zeros(2,num_cells*jumps_per_cell)
    vs[:,1] = v_end
    dx = d/jumps_per_cell

    abcd_L = abcd_shunt_element(impedence_inductor(L))
    abcd_L0 = abcd_series_element(impedence_inductor(L₀*dx))
    abcd_C = abcd_series_element(impedence_capacitator(C))
    abcd_C0 = abcd_shunt_element(impedence_capacitator(C₀*dx))

    res = Any[]

    for ω in ωs
        abcd_L = (ω)

        for i in collect(2:jumps_per_cell*num_cells)
            if i % jumps_per_cell == 0
                vs[:,i] = abcd_L(ω) * abcd_C(ω) * vs[:,i-1]
            else
                vs[:,i] = abcd_L0(ω) * abcd_C0(ω) * vs[:,i-1]
            end
        end

        append!(res, real(vs[:,end]))
    end

    return res
end


# function abcd_sim(ωs, L₀, C₀, C, L, d, num_cells)
#     vec = [1, 1/50]
#     data = []

#     for _ in collect(1:num_cells)
#         dd = []
#         for ω in ωs 
#             vec = abcd_clrh_cell(L₀, C₀, C, L, d)(ω) * vec
#             append!(dd, unpack(vec))
#         end
#         append!(data, vec)
#     end

#     # Convert the list of vectors into a 2D array
#     data = hcat(data...)

#     # Plot the heatmap
#     heatmap(data, cmap=:hot, aspect_ratio=:equal, xlabel="X values", ylabel="Y values")
# end

function abcd_sim(ωs, abcd_system)
    end_vals = [1, 1/50]

    return [
        unpack((abcd_system(ω) * end_vals)) for ω in ωs
        # unpack(abcd_system(ω), Complex(50)) for ω in ωs
    ]
end


function unpack(x::Vector)
    return abs((x[1] + 50*x[2])/(x[1] - 50*x[2]))
end


function unpack(system::Matrix, Z::Complex)
    a, c, b, d = system

    return abs((a+(b/Z)-((c*Z)+d))/(a+(b/Z)+((c*Z)+d)))
end


# L₀ = 1.01e-7
# C₀ = 2.83e-11

# L₀ = 1.58-7
# C₀ = 1.81e-11

L = 5.6e-9
C = 1e-12
d = 9e-3
cells = 10

# ω1 = 1.34e9 * 2π
# ω2 = 1.656e9 * 2π

# ω1 = 2.862e9 * 2π
# ω2 = 4.551e9 * 2π

# L₀ = 1/(ω1^2*C*d)
# C₀ = 1/(ω2^2*L*d)

plotlyjs()
ωs = collect(0e9: 1e5: 10e9) * 2π

# Permute omegas
# function permute_array(arr)
#     permutations = []
#     for i in 1:length(arr)
#         for j in 1:length(arr)
#             if i != j
#                 push!(permutations, (arr[i], arr[j]))
#             end
#         end
#     end
#     return permutations
# end

# tagged_ωs = [2.862e9, 4.551e9, 5.785e9, 6.797e9]

# for pair in permute_array(tagged_ωs)
#     ω1, ω2 = pair
#     ω1 *= 2π
#     ω2 *= 2π

#     text_ω1 = round(ω1/2π, digits=2)
#     text_ω2 = round(ω2/2π, digits=2)

#     print("Simulating ω1=$text_ω1, ω2=$text_ω2... ")

#     L₀ = 1/(ω1^2*C*d)
#     C₀ = 1/(ω2^2*L*d)

#     abcd_system = abcd_metamaterial_system(L₀, C₀, C, L, d, cells)
#     sim_results = abcd_sim(ωs, abcd_system)

#     plot(ωs/(2π), 20*log.(sim_results), title="ω1=$text_ω1, ω2=$text_ω2", show=true)
#     println("Done!")
# end


# Hard Coded Sim

L₀ = 242.892e-9
C₀ = 113.445e-12

# ω1 = 1.34e9 * 2π
# ω2 = 1.656e9 * 2π

# L₀ = 1/(ω1^2*C*d)
# C₀ = 1/(ω2^2*L*d)

# abcd_system = abcd_metamaterial_system(L₀, C₀, C, L, d, cells)
# sim_results = abcd_sim(ωs, abcd_system)

sim_results = abcd_sim(ωs, L₀, C₀, C, L, d, cells, 20)

plot(ωs/(2π), (sim_results), title="Hard Coded", show=true)

# Single Omega
# ω = 3e9 * 2*π
# abcd_system = abcd_metamaterial_system(L₀, C₀, C, L, d, 1)(ω)
# end_vals = [1, 1/50]
# init_vals = abcd_system * end_vals
# res = unpack(init_vals)
# print(res)

# println("Done")