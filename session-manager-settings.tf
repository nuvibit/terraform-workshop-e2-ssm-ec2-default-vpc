module "session-manager-settings" {
  source = "gazoakley/session-manager-settings/aws"

  linux_shell_profile = "exec /bin/bash"
}