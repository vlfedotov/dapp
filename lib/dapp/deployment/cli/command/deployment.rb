module Dapp::Deployment::CLI
  module Command
    class Deployment < ::Dapp::CLI
      SUBCOMMANDS = ['apply', 'mrproper', 'secret generate', 'secret key generate'].freeze

      banner <<BANNER.freeze
Usage: dapp deployment sub-command [sub-command options]

Available subcommands: (for details, dapp deployment SUB-COMMAND --help)

  dapp deployment apply [options] REPO IMAGE_VERSION
  dapp deployment secret key generate
  dapp deployment secret generate
  dapp deployment mrproper [options]

Options:
BANNER
    end
  end
end