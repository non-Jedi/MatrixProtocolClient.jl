using MatrixClientProtocol: Swagger

@testset "Utils" begin
    @test Swagger.typename("/_matrix/client/r0/my/fun/path") == :MyFunPath
    @testset "insertfield!" begin
        e = :(struct Foo; a::String end)
        Swagger.insertfield!(e, :b, :Int64)
        @test all(e.args[end].args[end-1:end] .== [:(a::String), :(b::Int64)])
        Swagger.insertfield!(e, :c, :(Vector{Int64}))
        @test all(e.args[end].args[end-2:end] .==
                  [:(a::String), :(b::Int64), :(c::Vector{Int64})])
    end
    @testset "juliatype" begin
        @test Swagger.juliatype("boolean") == :Bool
        @test Swagger.juliatype("array", "object") == :(Vector{Dict{String,Any}})
        @test Swagger.juliatype("array", "array", "object") == :(Vector{Vector{Dict{String,Any}}})
    end
    @testset "createpath" begin
        pathexpr = Swagger.createpath("/_matrix/client/r0/path/to/my/dreams")
        @test pathexpr.head == :(=)
        @test pathexpr.args[1] == :(path(::PathToMyDreams))
        @test all(pathexpr.args[end].args[end] .==
                  ["_matrix", "client", "r0", "path", "to", "my", "dreams"])
    end#@testset
end
