# ============================================================
# TheyDo
# ============================================================

tdr() { cd ~/Developer/TheyDo; }
td() { cd ~/Developer/TheyDo/theydo; }
tdweb() { cd ~/Developer/TheyDo/theydo/webapp; }
tdpw() { cd ~/Developer/TheyDo/theydo/packages/theydo-pw-e2e; }

td_run_yarn() {
  (td && yarn "$@")
}

alias lint="yarn lint:webapp"
alias format="yarn format:webapp"

alias fro="td_run_yarn dev:webapp"
alias ser="td_run_yarn dev:graphql-server"
alias worker="td_run_yarn dev:worker"
alias migrate="td_run_yarn workspace @theydo/core migration:run"
alias seed="td_run_yarn workspace @theydo/core elasticsearch:seed"
alias msser="migrate && seed && ser"
alias e2e="td_run_yarn workspace @theydo/pw-e2e test:ui"
alias icons="td_run_yarn workspace @theydo/iconography generate icons"
alias gql="td_run_yarn workspace @theydo/graphql generate-graphql"
alias gqlw="td_run_yarn workspace @theydo/webapp generate:graphql"
alias rmdist="td && cd graphql-server/ && rm -rf dist && yarn build && cd ../worker && rm -rf dist && yarn build && cd .."
