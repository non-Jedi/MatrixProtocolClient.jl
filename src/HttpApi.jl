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

export send, login, register
export HTTPget, HTTPput, HTTPpost

const BASE_PATH = Array{String,1}(["_matrix"; "client"; "r0"])

QueryParamsTypes = Union{String, Array{String,1}}
Enums.@enum HttpMethod HTTPget HTTPput HTTPpost

struct MatrixCredentials
    homeserver_url::String
    token::String
end

function MatrixCredentials(homeserver_url::String, json::Dict{String,Any})
    MatrixCredentials(homeserver_url, json["access_token"])
end

struct MatrixRequest{T<:Union{Dict{String,Any}}}
    method::HttpMethod
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
    body["bind_email"] = bind_email
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
    MatrixRequest(HTTPpost, endpoint, temp_creds,
                  body, query_params, Dict{String,String}())
end

function login(homeserver_url::String, login_type::String;
               user::String="", password::String="",
               medium::String="", address::String="",
               token::String="",
               device_id::String="", initial_device_display_name::String=""
               )::MatrixRequest{Dict{String,Any}}
    body = Dict{String,Any}()
    body["type"] = login_type
    if user != ""
        body["user"] = user
    end
    if password != ""
        body["password"] = password
    end
    if medium != ""
        body["medium"] = medium
    end
    if address != ""
        body["address"] = address
    end
    if token != ""
        body["token"] = token
    end
    if device_id != ""
        body["device_id"] = device_id
    end
    if initial_device_display_name != ""
        body["initial_device_display_name"] = initial_device_display_name
    end

    temp_creds = MatrixCredentials(homeserver_url, "")
    endpoint = Array{String,1}(["login"])
    MatrixRequest(HTTPpost, endpoint, temp_creds, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

function send(request::MatrixRequest{Dict{String,Any}})::Dict{String,Any}
    path = "/" * join(cat(1, BASE_PATH, request.endpoint)::Array{String,1}, "/")
    url = HTTP.URL(request.credentials.homeserver_url, path=path,
                   query=request.query_params)

    if length(request.credentials.token) > 0
        request.headers["Authorization"] = "Bearer " * request.credentials.token
    end
    if ! haskey(request.headers, "Content-Type")
        request.headers["Content-Type"] = "application/json"
    end

    json_body = JSON.json(request.body)
    response::HTTP.Response = if HTTPpost == request.method
        HTTP.post(url, body=json_body, headers=request.headers)::HTTP.Response
    elseif HTTPget == request.method
        HTTP.get(url, body=json_body, headers=request.headers)::HTTP.Response
    elseif HTTPput == request.method
        HTTP.put(url, body=json_body, headers=request.headers)::HTTP.Response
    else
        # This can't happen since all enum cases are handled above
        HTTP.Response(400, "{}")::HTTP.Response
    end

    JSON.parse(String(response))
end

end # module
