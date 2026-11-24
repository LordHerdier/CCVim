return {
    id = "runtime.keymap_noremap_leader_nop",
    description = "Non-recursive maps reach builtins under user-mapped keys; <leader> and <Nop> work in vim.keymap.set.", -- luacheck: ignore 631
    supports = { headless_nvim = false },
    run = function(ctx)
        local Assert = ctx.assert
        local b = ctx.backend
        b:api_build()
        local Event = b.mock.loadModule("lib.event")

        local function press(...)
            for _, name in ipairs({ ... }) do
                Event.ProcessEvent({ "key", keys[name], false, false, false })
            end
        end
        local function cursor()
            return b:eval_lua("table.concat(vim.api.nvim_win_get_cursor(0), ',')")
        end

        local err = b:eval_lua([[select(2, pcall(function()
            vim.g.mapleader = " "
            local map = vim.keymap.set
            -- Rotating maps whose targets are themselves user-mapped.
            map("n", "a", "j")
            map("n", "j", "l")
            map("n", "l", "k")
            map("n", "s", "<Nop>")
            map("n", "<leader>x", "j")
        end))]])
        Assert.eq("config with <leader>/<Nop> loads", err, nil)

        b:eval_lua("vim.api.nvim_buf_set_lines(0, 0, -1, false, {'abcdef','ghijkl','mnopqr'})")
        press("a")
        Assert.eq("noremap a->j uses builtin j despite user j map", cursor(), "2,0")
        press("j")
        Assert.eq("noremap j->l uses builtin l despite user l map", cursor(), "2,1")
        press("l")
        Assert.eq("noremap l->k uses builtin k", cursor(), "1,1")

        press("s")
        Assert.eq("<Nop> does nothing", b:eval_lua("vim.api.nvim_get_current_line()"), "abcdef")
        Assert.eq("<Nop> leaves normal mode", b:eval_lua("vim.api.nvim_get_mode().mode"), "n")

        press("space", "x")
        Assert.eq("<leader> expands to mapleader", cursor(), "2,1")
    end,
}
