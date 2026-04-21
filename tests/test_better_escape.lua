-- Tests for better-escape.nvim
-- Run with: nvim --headless -u tests/minimal_init.lua -c "lua dofile('tests/test_better_escape.lua')"

local be = require("better_escape")

local passed = 0
local failed = 0

--- Simple test assertion helper.
---@param name string
---@param condition boolean
---@param message? string
local function assert_test(name, condition, message)
    if condition then
        passed = passed + 1
        print("  PASS: " .. name)
    else
        failed = failed + 1
        print("  FAIL: " .. name .. (message and (" — " .. message) or ""))
    end
end

--- Run all tests.
local function run_tests()
    print("better-escape.nvim tests")
    print(string.rep("=", 60))

    -- Test: module loads correctly
    print("\n[Module loading]")
    assert_test("module returns a table", type(be) == "table")
    assert_test("setup function exists", type(be.setup) == "function")
    assert_test("waiting field exists", be.waiting ~= nil)
    assert_test("waiting is initially false", be.waiting == false)

    -- Test: setup with defaults
    print("\n[Setup with defaults]")
    be.setup()
    assert_test("setup with no args does not error", true)
    assert_test("waiting is false after setup", be.waiting == false)

    -- Test: setup with custom config
    print("\n[Setup with custom config]")
    be.setup({
        timeout = 100,
        mappings = {
            i = {
                k = {
                    j = "<Esc>",
                },
            },
        },
    })
    assert_test("setup with custom config does not error", true)

    -- Test: setup with default_mappings = false
    print("\n[Setup with default_mappings = false]")
    be.setup({
        default_mappings = false,
        mappings = {
            i = {
                j = {
                    k = "<Esc>",
                },
            },
        },
    })
    assert_test("setup with default_mappings=false does not error", true)

    -- Test: setup with function mapping
    print("\n[Setup with function mapping]")
    be.setup({
        mappings = {
            i = {
                j = {
                    k = function()
                        return "<Esc>"
                    end,
                },
            },
        },
    })
    assert_test("setup with function mapping does not error", true)

    -- Test: setup with disabled mapping
    print("\n[Setup with disabled mapping]")
    be.setup({
        mappings = {
            i = {
                j = {
                    j = false,
                },
            },
        },
    })
    assert_test("setup with disabled mapping does not error", true)

    -- Summary
    print("\n" .. string.rep("=", 60))
    print(
        string.format(
            "Results: %d passed, %d failed, %d total",
            passed,
            failed,
            passed + failed
        )
    )

    if failed > 0 then
        vim.cmd("cquit 1")
    else
        vim.cmd("quit")
    end
end

run_tests()
