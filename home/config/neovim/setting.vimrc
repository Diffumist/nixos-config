syntax on
set number
set encoding=utf-8
set showtabline=2
set termguicolors
set shell=/bin/bash
set fillchars=fold:\ ,vert:\│,eob:\ ,msgsep:‾
let g:dashboard_default_executive ='telescope'
lua << EOF
-- lspconfig
local lspkind = require('lspkind')
require'cmp'.setup {
  formatting = { format = lspkind.cmp_format({ with_text = false, maxwidth = 50}) },
  sources = { { name = 'buffer' }, { name = 'nvim_lsp' } }
}
local cap = vim.lsp.protocol.make_client_capabilities()
caps = require('cmp_nvim_lsp').update_capabilities(cap)
require'lspconfig'.rnix.setup{ capabilities = caps }
require'lspconfig'.tsserver.setup{ capabilities = caps }
require'lspconfig'.pyright.setup{ capabilities = caps }
require'lspconfig'.yamlls.setup{ capabilities = caps }
require'lspconfig'.rust_analyzer.setup{ capabilities = caps }

require'lsp_signature'.setup()
require'lsp_signature'.on_attach()

require('nvim-autopairs').setup{}
-- tweak
require'indent_blankline'.setup { space_char_blankline = " ", show_end_of_line = true }
require'lualine'.setup{ options = { theme = 'codedark'} }
require'neoscroll'.setup()
require'bufferline'.setup{
  options = { 
    show_close_icon = false,
    show_buffer_close_icons = false,
    custom_areas = {
      right = function()
        local result = {}
        local error = vim.lsp.diagnostic.get_count(0, [[Error]])
        local warning = vim.lsp.diagnostic.get_count(0, [[Warning]])
        local info = vim.lsp.diagnostic.get_count(0, [[Information]])
        local hint = vim.lsp.diagnostic.get_count(0, [[Hint]])
        if error ~= 0 then
          table.insert(result, {text = "  " .. error, guifg = "#EC5241"})
        end
        if warning ~= 0 then
          table.insert(result, {text = "  " .. warning, guifg = "#EFB839"})
        end
        if hint ~= 0 then
          table.insert(result, {text = "  " .. hint, guifg = "#A3BA5E"})
        end
        if info ~= 0 then
          table.insert(result, {text = "  " .. info, guifg = "#7EA9A7"})
        end
        return result
      end,
    },
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        highlight = "Directory",
        text_align = "left"
      }
    }
  }
}
require'toggleterm'.setup{}
require'nvim-tree'.setup { open_on_setup = true }
require'telescope'.setup { extensions = { fzf = { fuzzy = true } } }
require'telescope'.load_extension('fzf')
vim.g.material_style = "darker"
require'material'.setup()
vim.cmd[[colorscheme material]]
EOF