using Base.Test

println("Starting tests")
@time @testset "HTTP API" begin include("HttpApi_test.jl") end
