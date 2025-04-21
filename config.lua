Config = {
	Locale = 'en', -- The locale to use. (Removed old locales sorry, only supports en for now.)

	Skillcheck = true, -- If true, it makes the player have to do a skillcheck to break the display case.

	EnableMarker = true, -- If true, the marker will be shown when the player is near the store.

	UseBlips = true, -- If true, blips will be shown on the map.

	MaxWindows = 20, -- Maximum amount of windows that can be broken.

	Selling = {
		Jewels = {
			Min = 5, -- Minimum amount of jewels that can be sold.
			Max = 20, -- Maximum amount of jewels that can be sold.
			Price = 500 -- Price of each jewel.
		},
		Cooldown = 300 -- 5 minutes cooldown between sales
	},

	Police = {
		Jobs = { -- A list of jobs that are considered as cops.
			'police',
			'saso',
			'sast',
			'saso',
			'saso'
		},
		RequiredCops = {
			Sell = 3, -- How many cops are required to sell the jewels.
			Rob = 2 -- How many cops are required to rob the store.
		},
		Dispatch = 'melons' -- Supported dispatches: melons = melons_dispatch, rcore = rcore_dispatch
	},

	SecBetwNextRob = 3600 -- How many seconds between each robbery.
}

-- Locations have been moved to the shared/locations.lua.