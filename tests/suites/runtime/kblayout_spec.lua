return {
    id = "runtime.kblayout",
    description = "Remaps physical CC key codes through the 'kblayout' option.",
    supports = { headless_nvim = false },
    run = function(ctx)
        local Assert = ctx.assert
        local MockEnv = require("vim.tests.test_mocks")

        local mock = MockEnv.setup()

        local ok, err = pcall(function()
            local Event = mock.loadModule("lib.event")
            Event.LoadCommandModule()
            local semicolon = keys.semiColon or keys.semicolon

            local function type_keys(list, shifted)
                for _, k in ipairs(list) do
                    Event.ProcessEvent({ "key", k, false, shifted == true, false })
                end
            end

            -- Physical keys spelling "qwerty" positions of the Colemak word "hello".
            local hello = { keys.h, keys.k, keys.u, keys.u, semicolon }

            setMode("insert")
            type_keys(hello)
            local buf = windows[curwin].buffer
            Assert.eq("default qwerty layout leaves key codes alone", buf.lines[1], "hkuu;")

            options.set("kblayout", "colemak")
            type_keys(hello)
            type_keys({ semicolon, keys.p }, true)
            Assert.eq("colemak remaps letters and shifted punctuation", buf.lines[1], "hkuu;" .. "hello" .. "O:")

            -- Ctrl combos go through the remap too: physical ctrl-[ is unchanged.
            Event.ProcessEvent({ "key", keys.leftBracket, true, false, false })
            Assert.eq("ctrl-leftBracket still leaves insert mode", vimmode, "normal")

            local bad = pcall(options.set, "kblayout", "nope")
            Assert.eq("unknown layout is rejected", bad, false)
            Assert.eq("layout unchanged after rejected set", options.get("kblayout"), "colemak")
        end)

        mock.cleanup()

        if not ok then
            error(err)
        end
    end,
}
