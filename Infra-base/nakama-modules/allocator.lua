local nk = require("nakama")

local function allocate_and_notify(context, matched_users)
    nk.logger_info("MATCH FOUND → Requesting Agones Allocation")

    local url = "http://host.docker.internal:8443/gameserverallocation"
    local headers = { ["Content-Type"] = "application/json" }
    local body = nk.json_encode({
        namespace = "default",
        required = {
            matchLabels = {
                ["agones.dev/fleet"] = "fleet-example"
            }
        }
    })

    -- 1. Make the request
    local success, code, response = nk.http_request(url, "post", headers, body)

    -- 2. Robust check for success
    -- We parse the response regardless if 'code' looks weird but 'success' is true
    local data = nil
    if success then
        -- Try to decode the response even if code isn't exactly '200' 
        -- because your logs show Agones IS sending valid data.
        local status, decoded = pcall(nk.json_decode, response)
        if status then data = decoded end
    end

    -- 3. If we have data, use it!
    if data and data.address and data.ports and data.ports[1] then
        local ip = data.address
        local port = data.ports[1].port
        
        nk.logger_info("SUCCESS → Allocated Agones Server: " .. ip .. ":" .. port)

        local content = {
            host = ip,
            port = port
        }

        -- Notify players
        for _, user in ipairs(matched_users) do
            nk.notification_send(user.presence.user_id, "AgonesReady", content, 1, nil, true)
        end

        -- IMPORTANT: Return nil to satisfy Nakama matchmaker
        return nil
    end

    -- 4. Actual Error Handling if no data was found
    nk.logger_error("Agones allocation truly failed. Response: " .. tostring(response))
    return nil
end

nk.register_matchmaker_matched(allocate_and_notify)