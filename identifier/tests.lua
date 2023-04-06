local module = {}
local lu = require 'External.luaunit'
local identifier = require 'identifier'

function module:testIdentifiers()
    lu.assertEquals(identifier:match('_leading_underscore'), '_leading_underscore')
    lu.assertEquals(identifier:match('this has spaces '), 'this has spaces')
    lu.assertEquals(identifier:match('0this is not valid'), nil)
end

return module