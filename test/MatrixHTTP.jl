# [[file:~/repos/MatrixProtocolClient.jl/README.org::*MatrixHTTP.jl][MatrixHTTP.jl:2]]
using Test

# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request-test][login-request-test]]
import MatrixProtocolClient: MatrixHTTP

@testset "get login" begin
    let MH = MatrixHTTP, req = MH.GetLogin("example.com"), u = MH.url(req)
        @test MH.method(req) == "GET"
        @test u.host == "example.com"
        @test u.path == "/_matrix/client/r0/login"
        @test u.scheme == "https"
        @test isempty(u.query)
        @test isempty(MH.headers(req))
        @test isempty(MH.body(req))
    end#let
end#testset

# login-request-test ends here
# MatrixHTTP.jl:2 ends here
