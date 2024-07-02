return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		vim.opt.termguicolors = true
		require("bufferline").setup({
			options = {
				show_buffer_close_icons = false,
				-- 使用 nvim 内置lsp
				diagnostics = "nvim_lsp",
				separator_style = "padded_slope",
				-- 左侧让出 nvim-tree 的位置
				offsets = {
					{
						filetype = "NvimTree",
						text = "File Explorer",
						highlight = "Directory",
						text_align = "left",
					},
				},
			},
		})
	end,
}
