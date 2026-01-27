return {
    "williamboman/mason-lspconfig.nvim",
    config = function()
        require("mason-lspconfig").setup({
            --= ensure_installed = { "pylsp", "pyright", "lua_ls", "rust_analyzer", "gopls", "clangd" },
            automatic_enable  = { "pylsp", "pyright", "lua-ls", "rust_analyzer", "gopls", "clangd" },
        })
    end,
}
