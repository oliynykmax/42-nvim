-- [[ Configure LSP ]]--
--	This function gets run when an LSP connects to a particular buffer.
local on_attach = function(client, bufnr)
	-- NOTE: Remember that lua is a real programming language, and as such it is possible
	-- to define small helper and utility functions so you don't have to repeat yourself
	-- many times.
	--
	-- In this case, we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.
	local nmap = function(keys, func, desc)
		if desc then
			desc = 'LSP: ' .. desc
		end

		vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
	end

	nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
	nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

	nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
	nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
	nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
	nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
	nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
	nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

	-- Lesser used LSP functionality
	nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
	nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
	nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
	nmap('<leader>wl', function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, '[W]orkspace [L]ist Folders')

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
		vim.lsp.buf.format()
	end, { desc = 'Format current buffer with LSP' })

	-- WARN: this little bit here is *only* here to support nvim-navic if you decide to enable it.
	-- It might very well disappear one day!
	local status, navic = pcall(require, "nvim-navic")
		if status then
			if client.server_capabilities.documentSymbolProvider then
				navic.attach(client, bufnr)
			end
			vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
		end
end
local lspconfig = require('lspconfig')
local mason_lspconfig = require('mason-lspconfig')

-- Load the user-specified LSP servers.
local servers_config = require("config.lsp_servers") -- Renamed to avoid conflict

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
	pattern = "*.tpp",
	callback = function()
		vim.bo.filetype = "cpp"
	end
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

mason_lspconfig.setup {
	ensure_installed = vim.tbl_keys(servers_config),
    -- consider adding automatic_installation = true
}

-- NEW WAY to iterate and setup servers:
for server_name, server_specific_config in pairs(servers_config) do
    local opts = {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = server_specific_config.settings, -- Access settings from server_specific_config
        filetypes = server_specific_config.filetypes,
        cmd = server_specific_config.cmd
        -- any other options from server_specific_config can be merged here if needed
    }

    -- A common pattern is to let lspconfig handle defaults if not specified
    -- and only override what's in your server_specific_config
    -- So, you can pass the server_specific_config directly and lspconfig will merge
    -- if your server_specific_config contains keys like 'on_attach', 'capabilities'
    -- they would override the general ones.
    -- It's often cleaner to prepare a base opts table and then merge specifics.

    -- For example, if `server_specific_config` might also contain `on_attach` or `capabilities`
    -- and you want them to take precedence for that server:
    local final_opts = vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach = on_attach,
    }, server_specific_config) -- server_specific_config contains settings, filetypes, cmd etc.

    lspconfig[server_name].setup(final_opts)
end

-- Turn on diagnostic highlighting.
-- ... (rest of your file) ...
-- Load the user-specified LSP servers.


-- Turn on diagnostic highlighting.
vim.diagnostic.config {
	severity_sort = true,
	float = { border = 'rounded', source = 'if_many' },
	underline = {
		severity = {
			min = "WARN",
			max = "ERROR"
		}
	},
	virtual_text = {
		source = 'if_many',
		spacing = 2,
		prefix = function (diagnostic)
			if vim.g.have_nerd_font == false then
				return '▸'
			end
			local diagnostic_message = {
				[vim.diagnostic.severity.ERROR] = '󰅚',
				[vim.diagnostic.severity.WARN] = '󰀪',
				[vim.diagnostic.severity.INFO] = '󰋽',
				[vim.diagnostic.severity.HINT] = '󰌶',
			}
			return diagnostic_message[diagnostic.severity]
		end
	},
}
