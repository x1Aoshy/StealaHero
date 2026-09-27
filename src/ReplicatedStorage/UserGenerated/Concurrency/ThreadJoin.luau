-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIAm9zBWNsb2NrCWNvcm91dGluZQZzdGF0dXMEZGVhZAR0YXNrBHdhaXQKVGhyZWFkSm9pbgACBQIAAAALBAABBQIGgg8CABoapAICAAAEAICfAgECpAMFAAAQMIBSBAAAnwMCAvADAwAGAACAqQMBAIIDAgBHAQkAAAAAAKQEAgAABACAnwQBAiYDBAJ9AQMAAwAAAKkDAACCAwIApAMJAAAgcICfAwEBSADq/4IAAQAKAwEDAgQABACAAwMDBAQAEDCAAwUDBgMHBAAgcIAAFAgBGAAAAAIAAAAAAAEAAgAAAAAAAAABAAIAAPkJFQAAAAABAAABAwcAAAEPAAECA6MAAADAAAAAggACAAEGAAEAAQABGAATDQEAAAAAAZzUe5fbOjB8b4ntjn6ne6rszGzjrhARlg==

-- decompilation:
--!native
local function ThreadJoin(p1: thread, n1: number?) -- line: 20
	local elapsed = os.clock()

	while coroutine.status(p1) ~= "dead" do
		if n1 ~= nil and n1 <= os.clock() - elapsed then
			return false
		end

		task.wait()
	end

	return true
end

return ThreadJoin

