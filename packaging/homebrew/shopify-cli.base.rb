class ShopifyCli < Formula
  version 'SHOPIFY_CLI_VERSION'
  homepage 'https://shopify.github.io/shopify-app-cli'
  url "https://rubygems.org/downloads/shopify-cli-#{version}.gem"
  sha256 'SHOPIFY_CLI_GEM_CHECKSUM'
  desc <<~DESC
    Shopify CLI helps you build Shopify apps faster. It quickly scaffolds Node.js
    and Ruby on Rails embedded apps. It also automates many common tasks in the
    development process and lets you quickly add popular features, such as billing
    and webhooks.
  DESC

  bottle :unneeded

  depends_on 'git' => '2.13'

  def install
    system 'tar', '-xzf', cached_download, '--directory', buildpath

    (buildpath/'src').mkpath
    (buildpath/'symlink').mkpath
    system 'tar', '-xzf', buildpath/'data.tar.gz', '--directory', buildpath/'src'

    prefix.install buildpath/'src'

    exe = prefix/'src/bin/shopify'
    script = buildpath/'symlink/shopify'

    script_content = <<~SCRIPT
      #!/usr/bin/env bash
      #{RbConfig.ruby} --disable=gems -I #{prefix} #{exe} $@
    SCRIPT

    File.write(script, script_content)
    FileUtils.chmod("+x", script)

    bin.install script
  end
end
