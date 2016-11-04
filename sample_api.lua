--#ENDPOINT GET /development/device/data
-- Description: Get timeseries data for specific device
-- Parameters: ?identifier=<uniqueidentifier>&limit=<number>
local identifier = tostring(request.parameters.identifier) -- ?identifier=<uniqueidentifier>
local limit = tostring(request.parameters.limit) -- in minutes,if ?window=<number>
if true then
  local data = {}
  if limit == nil then limit = '30' end
  -- Assumes temperature and humidity data device resources
  --out = Timeseries.query({
  --  epoch='ms',
  --  q = "SELECT value FROM gps,speed,rpm WHERE identifier = '" ..identifier.."' time > now() - "..window.."m LIMIT 5000"})
    local q = TSQ.q()

  		:fields('value')
  		:from('speed','rpm','gps')
  		:limit(tonumber(limit))
                :orderby()

    local response = Timeseries.query{q = tostring(q) }
  data['timeseries'] = response
  return data
else
  http_error(403, response)
end

--#ENDPOINT GET /development/storage/keyvalue
-- Description: Show current key-value data for a specific unique device or for full solution
-- Parameters: ?device=<uniqueidentifier>
local identifier = tostring(request.parameters.device)

if identifier == 'all' or identifier == "nil" then
  local response_text = 'Getting Key Value Raw Data for: Full Solution: \r\n'
  local resp = Keystore.list()
  --response_text = response_text..'Solution Keys\r\n'..to_json(resp)..'\r\n'
  if resp['keys'] ~= nil then
    local num_keys = #resp['keys']
    local n = 1 --remember Lua Tables start at 1.
    while n <= num_keys do
      local id = resp['keys'][n]
      local response = Keystore.get({key = id})
      response_text = response_text..id..'\r\n'
      --response_text = response_text..'Data: '..to_json(response['value'])..'\r\n'
      -- print out each value on new line
      for key,val in pairs(from_json(response['value'])) do
        response_text = response_text.. '   '..key..':'.. val ..'\r\n'
      end
      n = n + 1
    end
  end
  return response_text
else
  local resp = Keystore.get({key = "identifier_" .. identifier})
  return 'Getting Key Value Raw Data for: Device Identifier: '..identifier..'\r\n'..to_json(resp)
end
