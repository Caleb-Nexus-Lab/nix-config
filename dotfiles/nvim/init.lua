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

  -- AUTO-COMPLÉTION
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({ { name = 'buffer' }, { name = 'path' } })
      })
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
  }
})

-- ==========================================
-- 4. OPTIONS & RACCOURCIS
-- ==========================================
vim.g.mapleader = " " 

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"

-- RACCOURCIS
local ok_tel, builtin = pcall(require, 'telescope.builtin')
if ok_tel then
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {}) -- Espace + ff : Chercher un fichier
    vim.keymap.set('n', '<leader>lg', builtin.live_grep, {})  -- Espace + lg : Chercher un mot
end

-- Espace + e : Ouvrir/Fermer l'explorateur de fichiers (Nvim-Tree)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })

-- Thème
vim.g.everforest_background = "hard"
vim.g.everforest_transparent_background = 1
vim.cmd.colorscheme "everforest"

-- Détection fichiers
vim.filetype.add({
  extension = { cfg = "haproxy" },
  filename = { ["interfaces"] = "interfaces" },
})
