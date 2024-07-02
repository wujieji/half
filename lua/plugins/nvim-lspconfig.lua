function LspKeybind(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	-- 绑定快捷键
	require("config.keybindings").lsp(buf_set_keymap)
end

return {
	"neovim/nvim-lspconfig",
	event = "BufEnter",
	config = function()
		require("lspconfig").lua_ls.setup({
			on_attach = LspKeybind,
		})
		require("lspconfig").pylsp.setup({
			on_attach = LspKeybind,
		})
		require("lspconfig").rust_analyzer.setup({
			on_attach = LspKeybind,
		})
		require("lspconfig").gopls.setup({
			on_attach = LspKeybind,
		})
	end,
}
