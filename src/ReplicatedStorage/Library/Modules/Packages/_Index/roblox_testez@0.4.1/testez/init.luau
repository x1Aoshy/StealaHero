-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSCmdldE1vZHVsZXMKY3JlYXRlUGxhbgdydW5QbGFuA3J1bgdyZXF1aXJlBnNjcmlwdAtFeHBlY3RhdGlvbg1UZXN0Qm9vdHN0cmFwCFRlc3RFbnVtCFRlc3RQbGFuC1Rlc3RQbGFubmVyC1Rlc3RSZXN1bHRzClRlc3RSdW5uZXILVGVzdFNlc3Npb24JUmVwb3J0ZXJzDFRleHRSZXBvcnRlchFUZXh0UmVwb3J0ZXJRdWlldBBUZWFtQ2l0eVJlcG9ydGVyAAIHAgMAAAAT+wIAAFIEAAC8AgJrAAAAAJ8CAwL7AwEATQMDEAEAAABSBAIAnwMCAvsEAgBNBAR1AgAAAFIFAwCfBAICUgUBAFIGBACfBQIBggABAAMDAQMCAwMADQQBGAAAAAAAAQAAAAABAAAAAAIAAAEOAAAAAA4AAAECAHWjAAAApAABAAAAAECkAQMAAAAgQE0BAf8EAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgJ3BQAAAJ8BAgKkAgEAAAAAQKQDAwAAACBATQMDvgYAAACfAgICpAMBAAAAAECkBAMAAAAgQE0EBPsHAAAAnwMCAqQEAQAAAABApAUDAAAAIEBNBQXiCAAAAJ8EAgKkBQEAAAAAQKQGAwAAACBATQYG+QkAAACfBQICpAYBAAAAAECkBwMAAAAgQE0HB78KAAAAnwYCAqQHAQAAAABApAgDAAAAIEBNCAjYCwAAAJ8HAgKkCAEAAAAAQKQJAwAAACBATQkJmgwAAABNCQnYDQAAAJ8IAgKkCQEAAAAAQKQKAwAAACBATQoKmgwAAABNCgodDgAAAJ8JAgKkCgEAAAAAQKQLAwAAACBATQsLmgwAAABNCwtoDwAAAJ8KAgLACxAAEgABABIABAASAAYA4gwSADALDDYRAAAAMAAM/wQAAAAwAQx3BQAAADACDL4GAAAAMAMM+wcAAAAwBAziCAAAADAFDPkJAAAAMAYMvwoAAAAwBwzYCwAAAOINEwAwCA3YDQAAADAJDR0OAAAAMAoNaA8AAAAwDQyaDAAAAIIMAgAUAwUEAAAAQAMGBAAAIEADBwMIAwkDCgMLAwwDDQMOAw8DEAMRAxIGAAMEBQoRBAUGBwgJCgsMBQMNDg8BAAEAARgAAAAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAACAAAACAEAAgABAAEAAQABAAEAAQABAAIBAAEAAQD9AAcBAAAAAAH7WfQVBtZ77AO93AF7fN2li0HjYcmdnhQ=

-- decompilation:
local Expectation = require(script.Expectation)
local TestBootstrap = require(script.TestBootstrap)
local TestEnum = require(script.TestEnum)
local TestPlan = require(script.TestPlan)
local TestPlanner = require(script.TestPlanner)
local TestResults = require(script.TestResults)
local TestRunner = require(script.TestRunner)
local TestSession = require(script.TestSession)
local TextReporter = require(script.Reporters.TextReporter)
local TextReporterQuiet = require(script.Reporters.TextReporterQuiet)
local TeamCityReporter = require(script.Reporters.TeamCityReporter)

return {
	run = function(p1, p2) -- line: 13
		-- upvalues: TestBootstrap (copy), TestPlanner (copy), TestRunner (copy)
		local v14 = TestBootstrap:getModules(p1)
		local v15 = TestPlanner.createPlan(v14)

		p2((TestRunner.runPlan(v15)))
	end,
	Expectation = Expectation,
	TestBootstrap = TestBootstrap,
	TestEnum = TestEnum,
	TestPlan = TestPlan,
	TestPlanner = TestPlanner,
	TestResults = TestResults,
	TestRunner = TestRunner,
	TestSession = TestSession,
	Reporters = {
		TextReporter = TextReporter,
		TextReporterQuiet = TextReporterQuiet,
		TeamCityReporter = TeamCityReporter
	}
}

