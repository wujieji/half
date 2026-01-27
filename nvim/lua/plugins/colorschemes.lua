return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        vim.cmd("colorscheme catppuccin")
    end,
}

-- return {
--     "folke/tokyonight.nvim",
--     lazy = false,
--     priority = 1000,
--     opts = {},
--     config = function()
--         vim.cmd("colorscheme tokyonight")
--     end,
-- }

-- return {
--     "Mofiqul/dracula.nvim",
--     lazy = false,
--     priority = 1000,
--     opts = {},
--     config = function()
--         vim.cmd("colorscheme dracula")
--     end,
-- }

-- return {
--     "EdenEast/nightfox.nvim",
--     lazy = false,
--     priority = 1000,
--     opts = {},
--     config = function()
--         vim.cmd("colorscheme dayfox")
--     end,
-- }

-- return {
--     "navarasu/onedark.nvim",
--     priority = 1000, -- make sure to load this before all the other start plugins
--     config = function()
--         require('onedark').setup {
--             style = 'cool'
--         }
--         -- Enable theme
--         require('onedark').load()
--     end
-- }
