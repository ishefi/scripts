-- ~/.config/nvim/init.lua

-- Essential Neovim options (you can add more from your .vimrc if needed)
vim.opt.nu = true              -- Line numbers
vim.opt.relativenumber = true  -- Relative line numbers
vim.opt.tabstop = 4            -- Number of spaces a tab counts for
vim.opt.shiftwidth = 4         -- Number of spaces to use for each step of (auto)indent
vim.opt.expandtab = true       -- Convert tabs to spaces
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.termguicolors = true   -- Enable true colors in the terminal
vim.opt.colorcolumn = "89"
vim.opt.clipboard = "unnamedplus"
vim.o.completeopt = 'menu,menuone'

-- === Plugin Management with lazy.nvim ===
-- This replaces your runtimepath and packpath setup for plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Mason for installing LSP servers
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "jedi_language_server" },
      })
    end,
  },

  -- LSP configuration using new vim.lsp.config API
  {
    "hrsh7th/cmp-nvim-lsp", -- For nvim-cmp to get LSP capabilities
    config = function()
      -- Get capabilities for autocompletion
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      -- Define LSP configuration for jedi_language_server
      vim.lsp.config('jedi_language_server', {
        cmd = { 'jedi-language-server' },
        filetypes = { 'python' },
        root_markers = { 'setup.py', 'setup.cfg', 'pyproject.toml', 'requirements.txt', '.git' },
        capabilities = capabilities,
        settings = {
          jedi = {
            -- Your jedi-language-server settings here
          }
        }
      })

      -- Set up keymaps when LSP attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local bufopts = { noremap=true, silent=true, buffer=bufnr }
          
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
        end,
      })

      -- Enable LSP for Python files
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'python',
        callback = function()
          vim.lsp.enable('jedi_language_server')
        end,
      })
    end,
  },

  -- nvim-cmp: Completion engine
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    end,
  },

  -- nvim-treesitter for syntax highlighting and more
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "python", "lua", "markdown", "markdown_inline" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
})
