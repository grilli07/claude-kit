# claude-kit

O meu conjunto de plugins, skills e regras do **Claude Code**, num lugar só, para ter o mesmo
processo em qualquer máquina.

- **[`CLAUDE.md`](CLAUDE.md)**: regras de roteamento. O Claude escolhe sozinho a skill certa para
  cada situação, sem eu precisar lembrar de comandos, e avisa qual está usando (`🧰 Skill: ...`).
- **[`manifest.json`](manifest.json)**: o que instalar (marketplaces, plugins, fontes de skills, MCPs extras).
- **[`skills/`](skills/)**: skills próprias ou avulsas. Cada pasta com um `SKILL.md` é copiada para `~/.claude/skills`.
- **[`install.ps1`](install.ps1)**: instala tudo e grava as regras no `~/.claude/CLAUDE.md`.
- **[`export.ps1`](export.ps1)**: atualiza o `manifest.json` com o que está instalado na máquina atual.
- **[`docs/analise-skills.md`](docs/analise-skills.md)**: o que cada pacote faz, onde se sobrepõem e quem vence.

## Instalar (uma linha)

Pré-requisitos: [Claude Code](https://docs.claude.com/en/docs/claude-code/setup) (ou o Code tab
do Claude Desktop aberto uma vez), [Node.js LTS](https://nodejs.org) e [Git](https://git-scm.com).

```powershell
irm https://raw.githubusercontent.com/grilli07/claude-kit/main/bootstrap.ps1 | iex
```

Isso clona o repo em `~/claude-kit` (ou dá `git pull` se já existir) e roda o instalador.
**Rodar de novo é o jeito de atualizar.** O instalador pula o que já existe e, no
`~/.claude/CLAUDE.md`, troca só o bloco entre os marcadores `claude-kit`. O resto do arquivo é
preservado, com backup.

Depois, abra uma sessão nova do Claude Code ou rode `/reload-plugins`.

### Opções do instalador

```powershell
cd ~/claude-kit
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
```

| Flag | Efeito |
|---|---|
| `-DryRun` | Só mostra o que faria |
| `-SkipRea` | Não instala o REA (engenharia reversa: MCP + skill) |
| `-NoClaudeMd` | Não mexe no `~/.claude/CLAUDE.md` |
| `-ConfigDir <pasta>` | Instala noutra pasta de config (`CLAUDE_CONFIG_DIR`) |

## Adicionar coisas

| Quero adicionar… | Como |
|---|---|
| Plugin (`/plugin install x@y`) ou skill de terceiros (`npx skills add dono/repo`) | Instale normalmente, depois rode `.\export.ps1`. Ele reescreve o `manifest.json`. |
| Uma skill minha | Crie `skills/<nome>/SKILL.md` |
| Uma regra de quando usar qual skill | Edite o [`CLAUDE.md`](CLAUDE.md) **deste repo** (não o de `~/.claude`) |

Depois:

```powershell
git add -A
git commit -m "add <coisa>"
git push
```

Nas outras máquinas, rode a linha do `irm ... | iex` de novo.

Puxar (`clone`/`pull`) não precisa de login porque o repo é público. Para fazer **push**,
autentique com a conta dona do repo (o Git Credential Manager abre o login do GitHub).

## O que não vai junto

- **MCPs pessoais** (Home Assistant etc.) e qualquer segredo, token ou chave.
- **Plugins sincronizados do claude.ai** e as skills `anthropic-skills:*`: vêm com a conta.

## Créditos

- [obra/superpowers](https://github.com/obra/superpowers), [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills),
  [supabase/agent-skills](https://github.com/supabase/agent-skills), [vercel-labs/skills](https://github.com/vercel-labs/skills),
  [nateherkai/scroll-craft](https://github.com/nateherkai/scroll-craft) e os plugins oficiais da Anthropic são instalados direto da fonte.
- `skills/reverse-engineer-anything`: [morluto/rea](https://github.com/morluto/rea), licença MIT (ver `LICENSE` na pasta).
