-- ==========================================
-- 1. PATCH DE COMPATIBILITÉ (NVIM 0.9.5)
-- ==========================================
if vim.fn.has("nvim-0.10") == 0 then
  vim.lsp.get_clients = vim.lsp.get_active_clients
end

-- ==========================================
-- 2. INSTALLATION AUTOMATIQUE DE LAZY.NVIM
-- ==========================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================
-- 3. CONFIGURATION DES PLUGINS
-- ==========================================
require("lazy").setup({

  -- Thème Everforest
  { "sainnhe/everforest", lazy = false, priority = 1000 },

  -- Transparence
  {
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup({ extra_groups = { "NormalFloat", "NvimTreeNormal" } })
    end
  },

  -- RECHERCHE (Verrouillé pour NVIM 0.9.5)
  {
    "nvim-telescope/telescope.nvim",
    tag = '0.1.8',
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  -- INDENTATION (Verrouillé pour NVIM 0.9.5)
  { "lukas-reineke/indent-blankline.nvim", version = "2.21.0", main = "ibl", opts = {} },

  -- EXPLORATEUR DE FICHIERS
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end
  },

  -- SNIPPETS (requis par nvim-cmp pour les complétions LSP)
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- AUTO-COMPLÉTION
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<Tab>']     = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-n>']     = cmp.mapping.select_next_item(),
          ['<C-p>']     = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        })
      })
    end
  },

  -- LSP — gestionnaire de serveurs
  { "williamboman/mason.nvim", config = function() require("mason").setup() end },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "nil_ls", "yamlls" },
        automatic_installation = true,
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local lspconfig    = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      for _, server in ipairs({ "lua_ls", "pyright", "rust_analyzer", "nil_ls", "yamlls" }) do
        lspconfig[server].setup({ capabilities = capabilities })
      end

      vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,  { desc = "Aller à la définition" })
      vim.keymap.set('n', 'K',          vim.lsp.buf.hover,        { desc = "Documentation" })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,       { desc = "Renommer" })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,  { desc = "Actions de code" })
      vim.keymap.set('n', '[d',         vim.diagnostic.goto_prev, { desc = "Diagnostic précédent" })
      vim.keymap.set('n', ']d',         vim.diagnostic.goto_next, { desc = "Diagnostic suivant" })
    end
  },

  -- Barre de statut
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = function() require('lualine').setup() end },

  -- Coloration syntaxique
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Interface moderne (Noice)
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    config = function()
      require("noice").setup({
        lsp = { signature = { enabled = false } },
        presets = { bottom_search = true, command_palette = true, long_message_to_split = true }
      })
    end
  },

  -- Fermeture automatique des paires (, [, {, "…
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
      local ok, cmp = pcall(require, "cmp")
      if ok then
        cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
      end
    end
  },

  -- Signes Git dans la gouttière (diff, blame…)
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },

})

-- ==========================================
-- 4. OPTIONS & RACCOURCIS
-- ==========================================
vim.g.mapleader = " "

vim.opt.termguicolors  = true
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.clipboard      = "unnamedplus"

-- Indentation (2 espaces, pas de tabs)
vim.opt.tabstop     = 2
vim.opt.shiftwidth  = 2
vim.opt.expandtab   = true
vim.opt.smartindent = true

-- RACCOURCIS
local ok_tel, builtin = pcall(require, 'telescope.builtin')
if ok_tel then
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Chercher un fichier" })
  vim.keymap.set('n', '<leader>lg', builtin.live_grep,  { desc = "Chercher dans les fichiers" })
end

vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true, desc = "Explorateur fichiers" })

-- Thème
vim.g.everforest_background            = "hard"
vim.g.everforest_transparent_background = 1
vim.cmd.colorscheme "everforest"

-- Détection fichiers
vim.filetype.add({
  extension = { cfg = "haproxy" },
  filename   = { ["interfaces"] = "interfaces" },
})
