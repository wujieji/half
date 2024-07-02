local ensure_list = {
	"c",
	"cpp",
	"lua",
	"go",
	"rust",
	"yaml",
	"json",
	"bash",
	"toml",
	"python",
	"dockerfile",
	"markdown",
	"make",
}

return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "BufRead" },
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			ensure_installed = ensure_list,
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		})
		vim.treesitter.language.register("mdx", "mardown")
	end,
}
