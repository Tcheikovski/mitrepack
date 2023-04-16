local M = {}

---@class mitrepack.crypto.PrivateKey
---@field p integer
---@field q integer
---@field d integer
local PrivateKey = {}

---@class mitrepack.crypto.PublicKey
---@field e integer
---@field n integer
local PublicKey = {}

local e = 65537

---@param bit_length integer
---@return mitrepack.crypto.PrivateKey
function M.generatePrivateKey(bit_length)
    math.randomseed(os.time())
    local p = math.random(2 ^ (bit_length - 1), 2 ^ bit_length - 1)
    local q = math.random(2 ^ (bit_length - 1), 2 ^ bit_length - 1)
    local totient = (p - 1) * (q - 1)
    local d = 1
    repeat
        d = d + 1
    until (d * e) % totient == 1
    local private_key = { p = p, q = q, d = d }
    return private_key
end

---@param private_key mitrepack.crypto.PrivateKey
---@return mitrepack.crypto.PublicKey
function M.derivePublicKey(private_key)
    local p = private_key.p
    local q = private_key.q
    local n = p * q
    local public_key = { e = e, n = n }
    return public_key
end

---@param message integer
---@param private_key mitrepack.crypto.PrivateKey
---@return integer
function M.sign(message, private_key)
    local p = private_key.p
    local q = private_key.q
    local n = p * q
    local d = private_key.d
    local signature = message ^ d % n
    return signature
end

---@param signature integer
---@param public_key mitrepack.crypto.PublicKey
---@return integer
function M.prime(signature, public_key)
    local e = public_key.e
    local n = public_key.n
    return signature ^ e % n
end

---@param message integer
---@param signature integer
---@param public_key mitrepack.crypto.PublicKey
---@return boolean
function M.verify(message, signature, public_key)
    local prime = M.prime(signature, public_key)
    return prime == message
end
