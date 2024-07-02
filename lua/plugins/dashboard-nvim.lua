return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		require("dashboard").setup({
			theme = "hyper",
			config = {
				header = {
					[[                                                     ]],
					[[                                                     ]],
					[[  ██╗    ██╗██╗   ██╗     ██╗██╗███████╗     ██╗██╗  ]],
					[[  ██║    ██║██║   ██║     ██║██║██╔════╝     ██║██║  ]],
					[[  ██║ █╗ ██║██║   ██║     ██║██║█████╗       ██║██║  ]],
					[[  ██║███╗██║██║   ██║██   ██║██║██╔══╝  ██   ██║██║  ]],
					[[  ╚███╔███╔╝╚██████╔╝╚█████╔╝██║███████╗╚█████╔╝██║  ]],
					[[   ╚══╝╚══╝  ╚═════╝  ╚════╝ ╚═╝╚══════╝ ╚════╝ ╚═╝  ]],
					[[                                                     ]],
					[[       [ After all, tomorrow is another day! ]       ]],
					[[                                                     ]],
				}, --your header
				center = {
					{
						icon = "  ",
						desc = "Projects                            ",
						action = "Telescope projects",
					},
					{
						icon = "  ",
						desc = "Recently files                      ",
						action = "Telescope oldfiles",
					},
					{
						icon = "  ",
						desc = "Edit keybindings                    ",
						action = "edit ~/.config/nvim/lua/keybindings.lua",
					},
					{
						icon = "  ",
						desc = "Edit Projects                       ",
						action = "edit ~/.local/share/nvim/project_nvim/project_history",
					},
				},
				footer = {}, --your footer
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
