function LspKeybind(client, bufnr)
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    -- 绑定快捷键
    require("config.keybindings").lsp(buf_set_keymap)
end

local symbols = { Error = "󰅙", Info = "󰋼", Hint = "󰌵", Warn = "" }
for name, icon in pairs(symbols) do
    local hl = "DiagnosticSign" .. name
    vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
end

return {
    "neovim/nvim-lspconfig",
    event = "BufEnter",
    config = function()
        local util = require("lspconfig/util")
        require("lspconfig").lua_ls.setup({
            on_attach = LspKeybind,
        })
        -- require("lspconfig").pylsp.setup({
        --     on_attach = LspKeybind,
        -- })
        require("lspconfig").pyright.setup({
            on_attach = LspKeybind,
            root_dir = util.root_pattern("venv", "pyrightconfig.json"),
            settings = {
                pyright = {
                    -- 自动检测项目根目录下的 venv 或 .venv
                    venvPath = ".",
                    venv = "venv",
                },
                python = {
                    analysis = {
                        typeCheckingMode = "basic",   -- 类型检查强度（basic/strict/off）
                        autoSearchPaths = true,       -- 自动搜索路径
                        useLibraryCodeForTypes = true -- 利用库代码推断类型
                    }
                }
            },
            on_init = function(client)
                local root = client.config.root_dir
                -- 优先检测 .venv
                local venv = util.path.join(root, ".venv")
                if not util.path.exists(venv) then
                    venv = util.path.join(root, "venv")
                end
                -- 更新配置
                if util.path.exists(venv) then
                    client.config.settings.python.pythonPath = util.path.join(venv, "bin", "python")
                    client.config.settings.pyright.venv = venv
                    client.config.settings.pyright.venvPath = root
                    client.notify("workspace/didChangeConfiguration")
                end
            end
        })
        require("lspconfig").rust_analyzer.setup({
            on_attach = LspKeybind,
        })
        require("lspconfig").gopls.setup({
            cmd = { "gopls", "serve" },
            filetypes = { "go", "gomod" },
            root_dir = util.root_pattern("go.mod", ".git", "go.work"),
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                },
                semanticTokens = true,
            },
            on_attach = LspKeybind,
        })
    end,
}
