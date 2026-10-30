-- Mise en forme des procédures pour le PDF (appelé par generer-pdf.py).
-- Sections numérotées et colorées, sommaire, encadrés, blocs de code titrés, figures.

local COULEURS = 4  -- sarcelle, vert, orange, violet (style.css)

local function echapper(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Un PDF ne peut pas pointer vers un fichier du dépôt : les liens locaux deviennent du texte.
function Link(el)
  if el.target:match("^https?:") or el.target:match("^#") then return el end
  return el.content
end

-- Encadrés : « Attention » ou « Important » en orange, le reste en remarque.
function BlockQuote(el)
  local debut = pandoc.utils.stringify(el):lower()
  local genre, titre = "remarque", "Remarque"
  if debut:match("^attention") then genre, titre = "attention", "Attention"
  elseif debut:match("^important") then genre, titre = "attention", "Important" end
  local contenu = pandoc.List({pandoc.RawBlock("html", '<p class="etiquette-encadre">' .. titre .. '</p>')})
  contenu:extend(el.content)
  return pandoc.Div(contenu, {class = "encadre " .. genre})
end

-- Blocs de code : barre de titre avec le langage, et le chemin du fichier s'il ouvre le bloc.
local LANGAGES = {bash = "Terminal", sh = "Terminal", powershell = "PowerShell", sql = "SQL",
                  ini = "Configuration", text = "Fichier ou sortie"}
function CodeBlock(el)
  local langage = el.classes[1] or "text"
  local chemin = el.text:match("^#%s*(/[%w%._%-/@]+)") or ""
  local barre = string.format('<div class="barre-code"><span>%s</span><span class="chemin">%s</span></div>',
    LANGAGES[langage] or langage, echapper(chemin))
  local style = (langage == "text") and "clair" or "sombre"
  return pandoc.Div({pandoc.RawBlock("html", barre), el}, {class = "bloc-code " .. style})
end

-- Image seule dans son paragraphe : figure numérotée, légendée par son texte alternatif.
function Para(el)
  if #el.content == 1 and el.content[1].t == "Image" then
    local image = el.content[1]
    local legende = '<p class="legende">' .. echapper(pandoc.utils.stringify(image.caption)) .. '</p>'
    return pandoc.Div({pandoc.Plain({image}), pandoc.RawBlock("html", legende)}, {class = "figure"})
  end
end

-- Titre (page de garde), sections colorées à tour de rôle, sommaire en tête.
function Pandoc(doc)
  local blocs, sommaire, section, n = pandoc.List(), {}, nil, 0
  local function fermer()
    if section then blocs:insert(pandoc.Div(section.contenu, {class = "section " .. section.couleur})) end
  end
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 1 then
      -- déjà sur la page de garde
    elseif b.t == "Header" and b.level == 2 then
      fermer()
      n = n + 1
      local texte = pandoc.utils.stringify(b)
      local numero, titre = texte:match("^(%d+)%.%s+(.+)$")
      numero = string.format("%02d", tonumber(numero) or n)
      titre = echapper(titre or texte)
      local couleur = "c" .. ((n - 1) % COULEURS + 1)
      table.insert(sommaire, string.format('<li class="%s"><span class="pastille">%s</span>%s</li>', couleur, numero, titre))
      section = {couleur = couleur, contenu = pandoc.List({pandoc.RawBlock("html", string.format(
        '<h2 class="titre-section"><span class="pastille">%s</span>%s</h2>', numero, titre))})}
    elseif section then
      section.contenu:insert(b)
    else
      blocs:insert(b)
    end
  end
  fermer()
  if #sommaire > 0 then
    blocs:insert(1, pandoc.RawBlock("html",
      '<nav class="sommaire"><p class="etiquette">Sommaire</p><ol>' .. table.concat(sommaire) .. '</ol></nav>'))
  end
  doc.blocks = blocs
  return doc
end
