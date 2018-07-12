using MatrixClientProtocol: MatrixSwagger

@testset "Utils" begin
    @test MatrixSwagger.typename("/_matrix/client/r0/my/fun/path") == :MyFunPath
    @testset "insertfield!" begin
        e = :(struct Foo; a::String end)
        MatrixSwagger.insertfield!(e, :b, :Int64)
        @test all(e.args[end].args[end-1:end] .== [:(a::String), :(b::Int64)])
        MatrixSwagger.insertfield!(e, :c, :(Vector{Int64}))
        @test all(e.args[end].args[end-2:end] .==
                  [:(a::String), :(b::Int64), :(c::Vector{Int64})])
    end
    @testset "juliatype" begin
        @test MatrixSwagger.juliatype("boolean") == :Bool
        @test MatrixSwagger.juliatype("array", "object") == :(Vector{Dict{String,Any}})
    end
end
