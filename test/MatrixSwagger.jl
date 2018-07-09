using MatrixClientProtocol: MatrixSwagger

@testset "Utils" begin
    @test MatrixSwagger.typename("/_matrix/client/r0/my/fun/path") == :MyFunPath
end
