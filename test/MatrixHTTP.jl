# [[file:~/repos/MatrixProtocolClient.jl/README.org::*MatrixHTTP.jl][MatrixHTTP.jl:2]]
using Test

# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request-test][login-request-test]]
import MatrixProtocolClient: MatrixHTTP
using HTTP

@testset "get login" begin
    let MH = MatrixHTTP, ep = MH.GetLogin("example.com"), u = MH.url(ep)
        let reqtuple = MH.request(ep)
            @test MH.method(ep) == "GET"
            @test u.host == "example.com"
            @test u.path == "/_matrix/client/r0/login"
            @test u.scheme == "https"
            @test isempty(u.query)
            @test isempty(MH.headers(ep))
            @test reqtuple[1] === HTTP.stack()
            @test reqtuple[2] == "GET"
            @test reqtuple[3] == u
            @test isempty(reqtuple[4])
            @test isempty(reqtuple[5])
        end#let
    end#let
end#testset

# login-request-test ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request-process-test][login-request-process-test]]
import MatrixProtocolClient: MatrixHTTP
const MH = MatrixHTTP
import HTTP: Response

@testset "get login process" begin
	let resp = Response(200; body=
		Vector{UInt8}("{\"flows\": [{\"type\": \"m.login.password\"}]}")),
		glr = MH.process_response(MH.GetLogin("example.com"), resp)
		@test length(glr.flows) == 1
		@test glr.flows[1] == "m.login.password"
	end#let
end#testset
# login-request-process-test ends here
# MatrixHTTP.jl:2 ends here
