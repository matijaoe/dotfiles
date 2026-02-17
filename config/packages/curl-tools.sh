# packages/curl-tools.sh
# To add a tool: copy the install command from the tool's website,
# wrap in quotes, and add a line below.
#
# Format: install_tool <command_name> "<install command>"

install_tool bun     "curl -fsSL https://bun.sh/install | bash"
install_tool deno    "curl -fsSL https://deno.land/install.sh | sh"
install_tool claude  "curl -fsSL https://claude.ai/install.sh | bash"
install_tool opencode "curl -fsSL https://opencode.ai/install | bash"
install_tool cursor  "curl https://cursor.com/install -fsS | bash"
install_tool amp     "curl -fsSL https://ampcode.com/install.sh | bash"
