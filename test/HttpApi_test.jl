using MatrixClient.HttpApi
import Base

function Base.:(==)(x::MatrixCredentials, y::MatrixCredentials)
    (x.homeserver_url == y.homeserver_url) & (x.token == y.token)
end
function Base.:(==)(x::HttpApi.MatrixRequest, y::HttpApi.MatrixRequest)
    for i in fieldnames(x)
        if getfield(x,i) != getfield(y,i)
            return false
        end
    end
    true
end

@testset "HttpApi types" begin
@test begin
    x = MatrixCredentials("https://matrix.org", "foobar")
    y = MatrixCredentials("https://matrix.org", Dict{String,Any}("access_token" => "foobar"))
    x == y
end
end # @testset

@testset "HttpApi request constructors" begin
@testset "register constructor" begin
creds = MatrixCredentials("https://matrix.org", "")
auth = Dict{String,Any}(
    "type" => "example.type.foo",
    "session" => "xxxxx",
    "example_credentials" => "verypoorsharedsecret"
)

@test begin
    x = HttpApi.MatrixRequest(HTTPpost, ["register"], creds,
                              Dict{String,Any}("bind_email" => false),
                              Dict{String,HttpApi.QueryParamsTypes}("kind" => "user"),
                              Dict{String,String}())
    y = register("https://matrix.org")
    x == y
end # @test

@test begin
    x = HttpApi.MatrixRequest(HTTPpost, ["register"], creds,
                              Dict{String,Any}("bind_email" => false),
                              Dict{String,HttpApi.QueryParamsTypes}("kind" => "guest"),
                              Dict{String,String}())
    y = register("https://matrix.org", true)
    x == y
end # @test

@test begin
    x = HttpApi.MatrixRequest(HTTPpost, ["register"], creds,
                              Dict{String,Any}(
                                  "auth" => auth,
                                  "bind_email" => false),
                              Dict{String,HttpApi.QueryParamsTypes}("kind" => "user"),
                              Dict{String,String}())
    y = register("https://matrix.org", false, auth)
    x == y
end # @test

@test begin
    x = HttpApi.MatrixRequest(HTTPpost, ["register"], creds,
                              Dict{String,Any}("bind_email" => true),
                              Dict{String,HttpApi.QueryParamsTypes}("kind" => "user"),
                              Dict{String,String}())
    y = register("https://matrix.org"; bind_email=true)
    x == y
end # @test

@test begin
    x = HttpApi.MatrixRequest(HTTPpost, ["register"], creds,
                              Dict{String,Any}(
                                  "username" => "cheeky_monkey",
                                  "password" => "ilovebananas",
                                  "device_id" => "GHTYAJCE",
                                  "initial_device_display_name" => "Jungle Phone",
                                  "bind_email" => false),
                              Dict{String,HttpApi.QueryParamsTypes}("kind" => "user"),
                              Dict{String,String}())
    y = register("https://matrix.org"; username="cheeky_monkey",
                 password="ilovebananas", device_id="GHTYAJCE",
                 initial_device_display_name="Jungle Phone")
    x == y
end # @test

end # @testset

@testset "login constructor" begin
creds = MatrixCredentials("https://matrix.org", "")

@test begin
    r1 = HttpApi.MatrixRequest(HTTPpost, Array{String,1}(["login"]), creds,
                               Dict{String,Any}("type" => "m.login.password",
                                                "user" => "username",
                                                "password" => "password"
                                                ),
                               Dict{String,HttpApi.QueryParamsTypes}(),
                               Dict{String,String}())
    r2 = login("https://matrix.org", "m.login.password", "password", "username")
    r1 == r2
end # @test

@test begin
    r1 = HttpApi.MatrixRequest(HTTPpost, Array{String,1}(["login"]), creds,
                               Dict{String,Any}("type" => "m.login.token",
                                                "token" => "foobar"),
                               Dict{String,HttpApi.QueryParamsTypes}(),
                               Dict{String,String}())
    r2 = login("https://matrix.org", "m.login.token"; token="foobar")
    r1 == r2
end # @test

@test begin
    r1 = HttpApi.MatrixRequest(HTTPpost, Array{String,1}(["login"]), creds,
                               Dict{String,Any}("type" => "m.login.token",
                                                "password" => "password",
                                                "medium" => "email",
                                                "address" => "test@example.com"),
                               Dict{String,HttpApi.QueryParamsTypes}(),
                               Dict{String,String}())
    r2 = login("https://matrix.org", "m.login.token", "password";
               medium="email", address="test@example.com")
    r1 == r2
end # @test

@test begin
    r1 = HttpApi.MatrixRequest(HTTPpost, Array{String,1}(["login"]), creds,
                               Dict{String,Any}("type" => "m.login.token",
                                                "token" => "foobar",
                                                "device_id" => "APWOEGIH",
                                                "initial_device_display_name" =>
                                                "device name"),
                               Dict{String,HttpApi.QueryParamsTypes}(),
                               Dict{String,String}())
    r2 = login("https://matrix.org", "m.login.token";
               token="foobar", device_id="APWOEGIH",
               initial_device_display_name="device name")
    println(r1)
    println(r2)
    r1 == r2
end # @test

end # @testset

end # @testset
