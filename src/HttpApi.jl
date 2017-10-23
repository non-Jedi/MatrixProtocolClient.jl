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

import HTTP
import JSON

BASE_PATH = "/_matrix/client/r0"

struct HttpApiData
    homeserver_url::String
    token::String
end

function register(homeserver_url::String,
                  auth::Associative==Dict(),
                  guest::Bool=false
                  )::HttpApiData

    query_params = if guest
        Dict("kind" => "guest")
    else
        Dict("kind" => "user")
    end
    path = BASE_PATH * "/register"
    url = HTTP.URL(homeserver_url, path=path, query=query_params)
    body = call_endpoint("POST", url)
