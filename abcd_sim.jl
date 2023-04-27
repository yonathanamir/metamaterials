using Plots


function gen_tl_γ_Z₀(R, G, C, L, d)
    function _inner(ω)
        a₁ = (R+im*ω*L)
        a₂ = (G+im*ω*C)

        γ = sqrt(a₁*a₂)
        Z₀ = sqrt(a₁/a₂)

        return γ, Z₀
    end

    return _inner
end


function abcd_transmission_line(R, G, C, L, d, l)
    gamma_z_func = gen_tl_γ_Z₀(R, G, C, L, d)

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
    tl1 = abcd_transmission_line(0, 0, C₀, L₀, d, 3*d/4)
    inductor = abcd_shunt_element(impedence_inductor(L))
    tl2 = abcd_transmission_line(0, 0, C₀, L₀, d, d/4)
    capacitator = abcd_series_element(impedence_capacitator(C))

    function _inner(ω)
        tl1_ω = tl1(ω)
        inductor_ω = inductor(ω)
        tl2_ω = tl2(ω)
        capacitator_ω = capacitator(ω)

        return tl1_ω * inductor_ω * tl2_ω * capacitator_ω
    end

    return _inner
end


function abcd_metamaterial_system(L₀, C₀, C, L, d, num_cells)
    function _inner(ω)
        sys = [1 0; 0 1]

        for _ in collect(1:num_cells)
            sys *= abcd_clrh_cell(L₀, C₀, C, L, d)(ω)
        end

        sys *= abcd_series_element(impedence_resistor(50))(ω)

        return sys
    end

    return _inner
end


function abcd_sim(ωs, abcd_system)
    end_vals = [1, 1/50]

    return [
        unpack((abcd_system(ω) * end_vals)) for ω in ωs
    ]
end


function unpack(x)
    return real((x[1] + 50*x[2])/(x[1] - 50*x[2]))
end


# L₀ = 1.01e-7
# C₀ = 2.83e-11

L₀ = 1.58-7
C₀ = 1.81e-11

L = 5.6e-9
C = 1e-12
d = 1e-2

ωs = collect(500e6: 1e7: 14e9) * 2*π
abcd_system = abcd_metamaterial_system(L₀, C₀, C, L, d, 10)
sim_results = abcd_sim(ωs, abcd_system)
plot(ωs/(2*π), sim_results)

# ω = 3e9 * 2*π
# abcd_system = abcd_metamaterial_system(L₀, C₀, C, L, d, 1)(ω)
# end_vals = [1, 1/50]
# init_vals = abcd_system * end_vals
# res = unpack(init_vals)
# print(res)
