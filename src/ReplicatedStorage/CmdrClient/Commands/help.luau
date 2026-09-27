-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
return {
	Name = "help",
	Description = "Displays a list of all commands, or inspects one command.",
	Group = "Help",
	Args = {{
		Type = "command",
		Name = "Command",
		Description = "The command to view information on",
		Optional = true
	}},
	ClientRun = function(p1, p2) -- line: 31
		if p2 then
			local Command = p1.Cmdr.Registry:GetCommand(p2)

			p1:Reply(`Command: { Command.Name }`, Color3.fromRGB(230.0, 126.0, 34.0))

			if Command.Aliases and #Command.Aliases > 0.0 then
				p1:Reply(`Aliases: { table.concat(Command.Aliases, ", ") }`, Color3.fromRGB(230.0, 230.0, 230.0))
			end

			p1:Reply(Command.Description, Color3.fromRGB(230.0, 230.0, 230.0))

			for i, v in ipairs(Command.Args) do
				p1:Reply(`#{ i } { v.Name }{ v.Optional ~= true and "" or "?" }: { v.Type } - { v.Description }`)
			end
		else
			p1:Reply("Argument Shorthands\n-------------------\n.   Me/Self\n*   All/Everyone\n**  Others\n?   Random\n?N  List of N random values\n")
			p1:Reply("Tips\n----\n• Utilize the Tab key to automatically complete commands\n• Easily select and copy command output\n")

			local Commands = p1.Cmdr.Registry:GetCommands()

			table.sort(Commands, function(p3, p4) -- line: 49
				if p3.Group and p4.Group then
					return p3.Group < p4.Group
				end

				return p3.Group
			end)

			local Group = nil

			for _, v in ipairs(Commands) do
				v.Group = v.Group or "No Group"

				if Group ~= v.Group then
					p1:Reply(`\n{ v.Group }\n{ string.rep("-", #v.Group) }`)
					Group = v.Group
				end

				p1:Reply(if not v.Description then v.Name else `{ v.Name } - { v.Description }`)
			end
		end

		return ""
	end
}

