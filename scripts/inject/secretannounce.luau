-- scripts/inject/secretannounce.luau (EGGS / secret heroes)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- SecretHeroAnnouncer (LocalScript): the client half of the secret hero spawn broadcast. The server half is
-- Controllers.AreaEggService.announceSecretSpawn, which fires Network["Eggs: SecretHeroSpawned"] to every client when
-- an egg of Secret rarity or better spawns; this script posts the [SERVER] chat line and shows the 6 s top banner.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/SecretHeroAnnouncer",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/SecretHeroAnnouncer.client.luau",
		create = true,
	},
}
