return {
  {
    -- =========================================================================
    -- PLUGIN: lualine.nvim
    -- Línea de estado (statusline) rápida, modular y altamente personalizable.
    -- =========================================================================
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- Proporciona los iconos para tipos de archivo
    },
    config = function()
      -- -----------------------------------------------------------------------
      -- FUNCIONES PERSONALIZADAS (Componentes propios)
      -- -----------------------------------------------------------------------

      -- 1. Obtiene los nombres de los servidores LSP activos en el archivo actual
      --    Ejemplo de salida: "󰒋 lua_ls, tsserver" (o vacío si no hay ninguno)
      local lsp_clients = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        if #clients == 0 then
          return ''
        end
        local names = {}
        for _, client in ipairs(clients) do
          table.insert(names, client.name)
        end
        return '󰒋 ' .. table.concat(names, ', ')
      end

      -- 2. Obtiene el nombre de la carpeta raíz del proyecto actual
      --    Ejemplo de salida: " mi-proyecto"
      local current_folder = function()
        return ' ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
      end

      -- -----------------------------------------------------------------------
      -- CONFIGURACIÓN DE LUALINE
      -- -----------------------------------------------------------------------
      require('lualine').setup {
        -- =====================================================================
        -- OPCIONES GLOBALES
        -- =====================================================================
        options = {
          -- Tema de colores: 'auto' detecta tu colorscheme actual (ej. ayu)
          theme = 'auto',

          -- Al dejarlos vacíos '', logramos el diseño "cuadrado / bloque plano"
          -- sin flechas de powerline ni bordes redondeados
          component_separators = '',
          section_separators = '',

          icons_enabled = true, -- Habilita iconos (requiere una Nerd Font instalada)

          -- Mantiene una única barra global en la parte inferior aunque abras varios splits
          globalstatus = true,

          -- Desactiva la barra en ventanas especiales como exploradores de archivos
          disabled_filetypes = {
            statusline = { 'dashboard', 'alpha', 'neo-tree', 'NvimTree' },
          },
        },

        -- =====================================================================
        -- SECCIONES DE LA BARRA DE ESTADO
        -- Estructura: [ A | B | C ] --------------------- [ X | Y | Z ]
        -- =====================================================================
        sections = {
          -- -------------------------------------------------------------------
          -- LUALINE_A: Extremo izquierdo (Modo actual de Neovim)
          -- -------------------------------------------------------------------
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                -- str contiene: "NORMAL", "INSERT", "VISUAL", etc.
                return ' ' .. str -- Le añade el icono de Neovim al inicio
              end,
              padding = { left = 1, right = 1 }, -- Espaciado interno mínimo
            },
          },

          -- -------------------------------------------------------------------
          -- LUALINE_B: Archivo y control de versiones (Git)
          -- -------------------------------------------------------------------
          lualine_b = {
            -- Nombre del archivo
            {
              'filename',
              file_status = true, -- Muestra iconos si fue modificado o es de solo lectura
              path = 0,           -- 0 = solo nombre (ej. "init.lua"), 1 = ruta relativa, 2 = ruta absoluta
              symbols = {
                modified = ' ●',          -- Símbolo cuando hay cambios sin guardar
                readonly = ' 󰌾',          -- Símbolo si el archivo es de solo lectura
                unnamed = '[Sin nombre]', -- Texto si el buffer no tiene archivo asignado
              },
              padding = { left = 1, right = 1 },
            },
            -- Rama de Git (Branch)
            {
              'branch',
              icon = '',
              padding = { left = 1, right = 1 },
            },
            -- Diferencias de Git (+ agregadas, ~ modificadas, - eliminadas)
            {
              'diff',
              symbols = {
                added = ' ',
                modified = ' ',
                removed = ' ',
              },
              padding = { left = 1, right = 1 },
            },
          },

          -- -------------------------------------------------------------------
          -- LUALINE_C: Centro/Izquierda media (vacío para mantenerlo limpio)
          -- -------------------------------------------------------------------
          lualine_c = {},

          -- -------------------------------------------------------------------
          -- LUALINE_X: Centro/Derecha media (Diagnósticos, LSP y Carpeta)
          -- -------------------------------------------------------------------
          lualine_x = {
            -- Diagnósticos y errores reportados por el LSP
            {
              'diagnostics',
              sources = { 'nvim_diagnostic' },
              symbols = {
                error = ' ',
                warn = ' ',
                info = ' ',
                hint = ' ',
              },
              padding = { left = 1, right = 1 },
            },
            -- Nombre del servidor LSP activo (función personalizada)
            {
              lsp_clients,
              color = { gui = 'bold' },
              padding = { left = 1, right = 1 },
            },
            -- Carpeta del proyecto actual (función personalizada)
            {
              current_folder,
              padding = { left = 1, right = 1 },
            },
          },

          -- -------------------------------------------------------------------
          -- LUALINE_Y: Tipo de archivo / Icono
          -- -------------------------------------------------------------------
          lualine_y = {
            {
              'filetype',
              colored = true,   -- Usa el color del icono según el lenguaje
              icon_only = false, -- Muestra tanto el icono como el texto (ej. "󰢱 lua")
              padding = { left = 1, right = 1 },
            },
          },

          -- -------------------------------------------------------------------
          -- LUALINE_Z: Extremo derecho (Posición: Línea y Columna)
          -- -------------------------------------------------------------------
          lualine_z = {
            {
              function()
                local line = vim.fn.line('.')
                local col = vim.fn.virtcol('.')
                return string.format(' %d:%d', line, col) -- Formato: " 23:39"
              end,
              padding = { left = 1, right = 1 },
            },
          },
        },
      }
    end,
  },
}
