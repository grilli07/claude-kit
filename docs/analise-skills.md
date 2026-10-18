# Análise das skills instaladas

Inventário de 2026-10-18 e as decisões de roteamento que viraram o `CLAUDE.md` global.

## 1. O que está instalado

| Origem | Como instala | Conteúdo |
|---|---|---|
| **superpowers** (plugin, `claude-plugins-official`) | `claude plugin install` | 14 skills de *processo*: brainstorming → writing-plans → subagent-driven-development / executing-plans → TDD → code review → verification → finishing-branch. Hook de início de sessão obriga a checar skills. |
| **agent-skills** (Addy Osmani, `npx skills`) | `npx skills add addyosmani/agent-skills` | 25 skills de *engenharia por fase*: idea-refine, interview-me, spec, planning, incremental, frontend, API, segurança, performance, CI/CD, docs, observabilidade, launch, doubt-driven… |
| **supabase/agent-skills** | `npx skills add` | `supabase`, `supabase-postgres-best-practices` |
| **vercel-labs/skills** | `npx skills add` | `find-skills` (achar/instalar skills novas) |
| **claude-security** (plugin oficial) | `claude plugin install` | Varredura de segurança multi-agente do repositório + geração de patches verificados |
| **frontend-design** (plugin oficial) | `claude plugin install` | Direção estética: tipografia, paleta, fugir do "visual de template" |
| **code-simplifier** (plugin oficial) | `claude plugin install` | Agente que simplifica código recém-alterado |
| **nateherk-design / scroll-craft** | marketplace `nateherkai/scroll-craft` | Landing pages premium guiadas por scroll, que se auto-verificam por screenshot |
| **reverse-engineer-anything (REA)** | MCP `rea-agents` + skill em `skills/` (MIT, [morluto/rea](https://github.com/morluto/rea)) | Engenharia reversa de binários, apps, firmware, Electron, APK |
| Embutidas no Claude Code | — | `/code-review`, `/security-review`, `/simplify`, `/init`, `run`, `dataviz`, artifacts… |

## 2. Filosofias diferentes

- **superpowers** é um **trilho**: cada skill termina chamando a próxima e há portões de aprovação (design → plano → modo de execução → destino da branch). Ótimo para *construir coisa nova do zero ao merge*.
- **agent-skills** é uma **caixa de ferramentas por fase**: skills independentes que não se chamam entre si. O meta-skill `using-agent-skills` é só uma árvore de decisão. Muito melhor em *domínios* (frontend, API, segurança, performance, deploy, observabilidade) que o superpowers nem cobre.
- Os dois têm um "meta-skill" que quer mandar no roteamento (`using-superpowers` e `using-agent-skills`). Sem uma regra, a escolha muda de sessão para sessão. **O `CLAUDE.md` global desempata**: instruções do usuário têm prioridade sobre as duas.

## 3. Sobreposições e quem vence

| Função | Concorrentes | Vence | Por quê |
|---|---|---|---|
| Desenhar algo novo | `superpowers:brainstorming`, `spec-driven-development` | **brainstorming** | Gera o design *e* puxa o resto do trilho. A spec seria um segundo documento igual. |
| Ideia ainda crua | `idea-refine`, brainstorming | **idea-refine → brainstorming** | idea-refine abre e fecha opções (divergir/convergir); o brainstorming desenha a solução escolhida. Complementares. |
| Objetivo nebuloso ("faz algo pro trabalho") | `interview-me`, brainstorming | **interview-me** só quando o *porquê/para quem* não está claro, ou quando pedido ("me entrevista") | O brainstorming já pergunta sobre o design; o interview-me cava a intenção. |
| PRD/spec formal para terceiros | `spec-driven-development` | **spec-driven-development** | Quando o documento é o entregável (ex.: proposta para a empresa). Nesse caso pula a spec do brainstorming. |
| Plano de execução | `superpowers:writing-plans`, `planning-and-task-breakdown` | **writing-plans** | Já está ligado à execução por subagentes. `planning-and-task-breakdown` só para estimativa/roadmap sem executar. |
| Implementação | `subagent-driven-development`/`executing-plans`, `incremental-implementation` | **superpowers** executa; **incremental-implementation** é a disciplina dentro de cada tarefa | Sem plano formal (mudança média), usar incremental-implementation direto. |
| Testes | `superpowers:test-driven-development`, `test-driven-development` | **superpowers:TDD** | Está no trilho. Os dois dizem o mesmo (red-green-refactor). |
| Debug | `superpowers:systematic-debugging`, `debugging-and-error-recovery` | **systematic-debugging** | Mais rígido sobre "causa raiz antes de corrigir". |
| Revisar a própria mudança | `/code-review`, `superpowers:requesting-code-review`, `code-review-and-quality` | **/code-review** (bugs) + o review do trilho | `code-review-and-quality` para revisar código de *outra pessoa/PR* ou review multi-eixo pedido explicitamente. |
| Simplificar | `/simplify`, `code-simplifier` (plugin), `code-simplification` | **/simplify** no diff atual; **code-simplification** para refatorar código antigo | O plugin code-simplifier é redundante com `/simplify`. |
| Segurança | `security-and-hardening`, `/security-review`, `claude-security` | Os três, em **momentos diferentes** | hardening *enquanto escreve* (input, auth, segredos); `/security-review` *antes do push*; `claude-security` *antes de expor algo à internet* ou auditoria completa. |
| Frontend | `frontend-design`, `frontend-ui-engineering`, `scroll-craft` | **Depende do tipo** | scroll-craft = landing page/site de marca com scroll; frontend-design = estética de qualquer UI nova; frontend-ui-engineering = componentes, estado, acessibilidade, responsivo. Design + engineering combinam bem. |
| Verificar antes de dizer "pronto" | `verification-before-completion`, princípio "Verify" do agent-skills | **verification-before-completion** | Sempre, em qualquer tarefa. |

## 4. Skills que *só* um lado tem (valor extra)

- **doubt-driven-development**: revisão adversarial com contexto limpo. Usar quando o erro é caro: produção, ERP/banco de dados, servidores, virtualização, migrações, apagar dados, auth.
- **source-driven-development**: decidir com base na documentação oficial. Muito útil para APIs que mudam rápido (Home Assistant, ESPHome, Frigate, Proxmox, Next.js).
- **constraint-driven-development**: escreve o `CONSTRAINTS.md` com a régua de qualidade. Para projetos que vão durar.
- **context-engineering**: montar o `CLAUDE.md` de um projeto novo.
- **api-and-interface-design**, **performance-optimization**, **observability-and-instrumentation**, **ci-cd-and-automation**, **shipping-and-launch**, **deprecation-and-migration**, **documentation-and-adrs**, **git-workflow-and-versioning**: domínios que o superpowers não cobre.
- **superpowers:using-git-worktrees**, **dispatching-parallel-agents**, **finishing-a-development-branch**, **receiving-code-review**, **writing-skills**: mecânica de fluxo que o agent-skills não tem.

## 5. Avisos

- `browser-testing-with-devtools` exige o MCP `chrome-devtools`, que **não está configurado**. Por enquanto, usar o navegador embutido do app (ou o Claude in Chrome) para testar no browser.
- `scroll-craft` pode gerar imagens/vídeos pelo **kie.ai**, o que precisa de chave própria. Sem ela, use fotos e vídeos seus.
- `claude-security` é pesado (vários agentes). Não rodar a cada commit.
- Tarefas triviais (pergunta, edição de 1–2 linhas, um comando) **não** passam pelo trilho completo. Senão o superpowers transforma tudo em brainstorm.
