-- 文件浏览器
return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("nvim-tree").setup({
            sort = {
                sorter = "case_sensitive",
            },
            view = {
                width = 35,
            },
            renderer = {
                group_empty = true,
            },
            diagnostics = {
                enable = true,
                show_on_dirs = true,
            },
            update_focused_file = {
                enable = true,
            },
        })
    end,
}
