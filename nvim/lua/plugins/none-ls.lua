return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")
        local formatting = null_ls.builtins.formatting
        null_ls.setup({
            debug = true,
            sources = {
                formatting.shfmt,
                formatting.stylua,
                formatting.gofmt,
                formatting.goimports,
                formatting.black,
                -- formatting.rustfmt,
            },
            on_attach = function(client, bufnr)
                local function buf_set_keymap(...)
                    vim.api.nvim_buf_set_keymap(bufnr, ...)
                end
                local opts = { noremap = true, silent = true }
                -- 格式化当前缓冲区
                buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.format { async = true }<CR>", opts)
            end,
        })
    end,
}
