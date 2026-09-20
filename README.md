# RDAP | Organização do trabalho

Aplicação em português com Dashboard, Cronograma, Estatísticas, Planejamento e Relatórios. Frontend estático em `dist/`, com Supabase Auth e PostgreSQL.

## Funcionalidades

- Cadastro com nome, e-mail, telefone, nome de usuário, ID do trabalho e confirmação de senha.
- Login com e-mail e senha. A confirmação de e-mail segue a configuração do Supabase Auth.
- Atividades com categoria, prioridade, descrição, datas e status. Criação, edição e exclusão.
- Calendário mensal com a duração das atividades.
- Indicadores calculados com dados reais e histórico de conclusão.
- Relatórios por período, salvos como retratos dos dados, exportação CSV e impressão em PDF pelo navegador.
- Layout adaptado a celular e computador.

## Banco de dados e acesso

Projeto Supabase: `vcnfstqoysljqhblpimz`. O schema aplicado está em `supabase/schema.sql` e registrado na migração remota `work_organization_initial`.

As tabelas `profiles`, `tasks` e `reports` têm RLS habilitada. Cada usuário acessa somente os próprios registros. O ID do trabalho é informativo e **não concede acesso a outra conta**. A senha é gerenciada exclusivamente pelo Supabase Auth. O código do navegador contém somente a chave publicável, nunca uma chave secreta ou `service_role`.

A criação de perfis usa uma função interna chamada pelo gatilho de cadastro, com acesso revogado para clientes. Os nomes de usuário são únicos e aceitam 3 a 32 letras minúsculas, números e sublinhado.

## Executar e hospedar

Sirva o diretório `dist/` por HTTP/HTTPS. Não há etapa de compilação. As rotas são `#/dashboard`, `#/cronograma`, `#/estatisticas`, `#/planejamento`, `#/relatorios`, `#/login` e `#/cadastro`. GitHub Pages pode servir os arquivos de `dist/` como artefato de publicação; nenhuma chave secreta é necessária.

O arquivo `dist/supabase.js` é a distribuição UMD do pacote `@supabase/supabase-js` **2.57.4**, distribuído sob licença MIT, obtida de `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.57.4/dist/umd/supabase.js`. Está incluído no repositório para evitar dependência de CDN em execução.

## Configuração de e-mail

No Supabase, em Authentication > URL Configuration, configure a URL final em Site URL e Redirect URLs. Em Authentication > Email, mantenha a confirmação de e-mail conforme a política desejada e configure um provedor SMTP para envios de produção. O cadastro funciona com o Supabase Auth existente; políticas de envio, limites de e-mail e redirecionamento pertencem ao projeto Supabase. Nunca desative a confirmação para contornar um problema de entrega.

O site publicado no Sites permanece privado ao proprietário por padrão. Essa restrição de hospedagem é independente do login Supabase. A liberação para outros visitantes exige ajustar a audiência da hospedagem.
