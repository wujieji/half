return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				theme = "auto",
				component_separators = { left = "|", right = "|" },
				section_separators = { left = " ", right = "" },
			},
			extensions = { "nvim-tree", "toggleterm" },
			sections = {
                lualine_b = {
                    "branch"
                },
				lualine_c = {
					"filename",
					{
						"lsp_progress",
						spinner_symbols = {
							" ",
							" ",
							" ",
							" ",
							" ",
							" ",
						},
					},
				},
				lualine_x = {
					"filesize",
					{
						"fileformat",
						symbols = {
							unix = "", -- e712
							dos = "", -- e70f
							mac = "", -- e711
						},
					},
					"encoding",
					"filetype",
				},
			},
		})
	end,
}
