#=
Copyright 2017 Adam Beckmeyer

This file is part of MatrixClient.jl.

MatrixClient.jl is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

MatrixClient.jl is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
MatrixClient.jl. If not, see <http://www.gnu.org/licenses/>.
=#

module HttpApi

import HTTP
import JSON
import Base.Enums

const BASE_PATH = Array{String,1}(["_matrix"; "client"; "r0"])

QueryParamsTypes = Union{String, Array{String,1}}

struct MatrixCredentials
    homeserver_url::String
    token::String
end

function MatrixCredentials(json::Dict{String,Any}, homeserver_url::String)
    MatrixCredentials(homeserver_url, json["access_token"])
end

struct MatrixRequest{T<:Union{Dict{String,Any}}}
    method::String
    endpoint::Array{String,1}
    credentials::MatrixCredentials
    body::T
    query_params::Dict{String,QueryParamsTypes}
    headers::Dict{String,String}
end

function register(homeserver_url::String;
                  guest::Bool=false,
                  auth::Dict{String,Any}=Dict{String,Any}(),
                  bind_email::Bool=false,
                  username::String="",
                  password::String="",
                  device_id::String="",
                  initial_device_display_name::String=""
                  )::MatrixRequest{Dict{String,Any}}

    query_params = if guest
        Dict{String,QueryParamsTypes}("kind" => "guest")
    else
        Dict{String,QueryParamsTypes}("kind" => "user")
    end

    body = Dict{String,Any}()
    if length(auth) > 0
        body["auth"] = auth
    end
    if bind_email
        body["bind_email"] = true
    end
    if username != ""
        body["username"] = username
    end
    if password != ""
        body["password"] = password
    end
    if device_id != ""
        body["device_id"] = device_id
    end
    if initial_device_display_name != ""
        body["initial_device_display_name"] = initial_device_display_name
    end

    temp_creds = MatrixCredentials(homeserver_url, "")
    endpoint = Array{String,1}(["register"])
    MatrixRequest("POST", endpoint, temp_creds, body, query_params,
                  Dict{String,String}())
end

function matrix_send(request::MatrixRequest{Dict{String,Any}})::Dict{String,Any}
    path = "/" * join(cat(1, BASE_PATH, request.endpoint), "/")
    url = HTTP.URL(request.credentials.homeserver_url, path=path,
                   query=request.query_params)

    if length(request.credentials.token) > 0
        request.headers["Authorization"] = "Bearer " * request.credentials.token
    end
    if ! haskey(request.headers, "Content-Type")
        request.headers["Content-Type"] = "application/json"
    end

    json_body = JSON.json(request.body)
    if "POST" == request.method
        response = HTTP.post(url, body=json_body,
                             headers=request.headers)::HTTP.Response
    elseif "GET" == request.method
        response = HTTP.get(url, body=json_body,
                            headers=request.headers)::HTTP.Response
    elseif "PUT" == request.method
        response = HTTP.put(url, body=json_body,
                            headers=request.headers)::HTTP.Response
    end

    JSON.parse(String(response))
end

end # module
