local module = { AST = {}, code = {}}

-- AST version hash is generated from parser.lua.
-- Code version hash is generated from toStackVM.lua, with the AST version hash as a seed.

-- An improvement would be to use the hash of the compiled Lua code instead.

-- Workflow: Change the parser, invalidate the version.
-- Later stages will automatically report an error and refuse to continue.
-- Update each stage and its associated version.
--
-- Do not update the hash unless there's a reasonable certainty of compatibility,
-- the point is for it to be a reminder.
-- Setting everything to latest makes the reminder worthless.
module.AST.TypeChecker = 3498909003
module.AST.GraphViz = 3498909003
module.AST.StackVM = 3498909003
module.code.StackVM = 1821081575
return module