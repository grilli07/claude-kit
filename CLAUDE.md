<!-- claude-kit:begin (gerenciado por claude-kit/install.ps1; edite no repo, não aqui) -->
# Roteamento de skills

O usuário não decora nomes de skills. Escolha e aplique sozinho a skill certa para cada situação,
seguindo esta tabela. Estas regras têm prioridade sobre os meta-skills `using-superpowers` e
`using-agent-skills` quando os dois discordarem.

## Transparência
- Ao aplicar uma skill, diga numa linha curta qual e por quê: `🧰 Skill: <nome> (<motivo>)`.
  Assim o usuário aprende os nomes com o uso.
- Nunca rode duas skills da mesma função na mesma tarefa (ex.: brainstorming + spec-driven-development).

## Tamanho da tarefa
- **Trivial** (pergunta, explicação, edição de 1–2 linhas, um comando, consulta de estado):
  sem trilho. Só faça. Brainstorm/plano aqui atrapalha.
- **Média** (uma funcionalidade pequena, um bug, um script): skill de domínio +
  `incremental-implementation` + `superpowers:verification-before-completion`.
- **Grande/nova** (projeto, app, integração, algo que leva horas): trilho completo do superpowers.

## Trilho principal (coisa nova)
1. Ideia crua ou vaga → `idea-refine`; depois → `superpowers:brainstorming`.
   Objetivo/público nebuloso, ou o usuário pede "me entrevista" → `interview-me` antes.
2. Desenho → `superpowers:brainstorming` (o único que gera o design doc).
   Exceção: o entregável é um PRD/spec formal para outras pessoas → `spec-driven-development` no lugar.
3. Plano → `superpowers:writing-plans`. (`planning-and-task-breakdown` só para estimativa/roadmap sem executar.)
4. Execução → `superpowers:subagent-driven-development` ou `superpowers:executing-plans`;
   dentro de cada tarefa, a disciplina de `incremental-implementation`.
5. Testes → `superpowers:test-driven-development` (não a versão do agent-skills).
6. Fim → `superpowers:verification-before-completion` → `superpowers:finishing-a-development-branch`.
Projeto que vai durar e ainda não tem régua de qualidade → ofereça uma vez `constraint-driven-development`.

## Por situação
| Situação | Skill |
|---|---|
| Bug, erro, teste falhando, "parou de funcionar" | `superpowers:systematic-debugging` |
| Landing page, site de marca, "site bonito", animação com scroll | `nateherk-design:scroll-craft` |
| Qualquer UI nova: aparência, tipografia, paleta | `frontend-design:frontend-design` |
| Componentes, estado, responsivo, acessibilidade | `frontend-ui-engineering` |
| Gráfico, dashboard, visualização de dados | `dataviz` |
| API, endpoint, contrato entre módulos | `api-and-interface-design` |
| Lib/framework cuja API muda rápido (Home Assistant, ESPHome, Frigate, Proxmox, Next.js…) | `source-driven-development` |
| Código com input externo, login, segredos, integrações | `security-and-hardening` (enquanto escreve) |
| Antes de push/PR de algo sensível | `/security-review` |
| Antes de expor serviço na internet (Cloudflare tunnel, Vercel) ou auditoria completa | `claude-security:claude-security` |
| Revisar minha mudança antes de commit/merge | `/code-review` |
| Revisar código/PR de outra pessoa, review multi-eixo | `code-review-and-quality` |
| Código funciona mas está confuso | `/simplify` (diff atual) ou `code-simplification` (código antigo) |
| Lento, pesado, query demorada | `performance-optimization` |
| Logs, métricas, alertas | `observability-and-instrumentation` |
| Commits, branches, versões, changelog | `git-workflow-and-versioning` |
| Pipeline CI/CD, GitHub Actions | `ci-cd-and-automation` |
| Deploy/colocar em produção | `shipping-and-launch` |
| Migrar/aposentar sistema, renomear coluna em produção | `deprecation-and-migration` |
| Documentar decisão, README, ADR | `documentation-and-adrs` |
| Postgres / Supabase | `supabase-postgres-best-practices` / `supabase` |
| Binário, app sem código-fonte, firmware, APK, Electron | `reverse-engineer-anything` |
| Montar CLAUDE.md/contexto de um projeto novo | `context-engineering` |
| Trabalho paralelo independente | `superpowers:dispatching-parallel-agents` |
| "Existe skill pra X?" / nada desta tabela serve | `find-skills` |

## Alto risco
Erro caro ou irreversível (produção do trabalho, ERP/SQL, servidores, Proxmox, apagar dados,
migração, autenticação): depois do plano e antes de executar, rode `doubt-driven-development`.

## Avisos
- `browser-testing-with-devtools` precisa do MCP chrome-devtools. Se ele não estiver configurado,
  teste no navegador embutido do app ou no Claude in Chrome.
- `claude-security` é pesado (vários agentes). Não rode a cada commit.
<!-- claude-kit:end -->
