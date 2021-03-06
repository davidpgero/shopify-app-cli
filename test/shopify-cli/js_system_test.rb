# frozen_string_literal: true
require 'project_types/node/test_helper'

module ShopifyCli
  class JsSystemTest < MiniTest::Test
    def setup
      project_context('app_types', 'node')
      @system = JsSystem.new(ctx: @context)

      @execution_mock = Minitest::Mock.new
      @execution_mock.expect(:executed, nil)
    end

    def test_call_executes_yarn_lambda_if_yarn_is_available
      @system.stubs(:yarn?).returns(true)

      @system.call(yarn: -> { @execution_mock.executed }, npm: -> { raise Exception })

      @execution_mock.verify
    end

    def test_call_executes_npm_lambda_if_yarn_is_unavailable
      @system.stubs(:yarn?).returns(false)

      @system.call(yarn: -> { raise Exception }, npm: -> { @execution_mock.executed })

      @execution_mock.verify
    end

    def test_call_executes_yarn_command_array_if_yarn_is_available
      yarn_command = %w(install --silent)

      @system.stubs(:yarn?).returns(true)
      mock_kit_system(JsSystem::YARN_CORE_COMMAND, *yarn_command)

      @system.call(yarn: yarn_command, npm: ['npm'])
    end

    def test_call_executes_npm_command_array_if_yarn_is_unavailable
      npm_command = %w(install --other)

      @system.stubs(:yarn?).returns(false)
      mock_kit_system(JsSystem::NPM_CORE_COMMAND, *npm_command)

      @system.call(yarn: ['yarn'], npm: npm_command)
    end

    def test_call_executes_yarn_command_string_if_yarn_is_available
      yarn_command = 'install'

      @system.stubs(:yarn?).returns(true)
      mock_kit_system(JsSystem::YARN_CORE_COMMAND, yarn_command)

      @system.call(yarn: yarn_command, npm: 'npm')
    end

    def test_call_executes_npm_command_string_if_yarn_is_unavailable
      npm_command = 'install'

      @system.stubs(:yarn?).returns(false)
      mock_kit_system(JsSystem::NPM_CORE_COMMAND, npm_command)

      @system.call(yarn: 'yarn', npm: npm_command)
    end

    def test_call_on_class_proxies_to_the_instance_version_of_call
      yarn_command = 'yarn'
      npm_command = 'npm'
      JsSystem.any_instance.expects(:call).with(yarn: yarn_command, npm: npm_command).once

      JsSystem.call(@context, yarn: yarn_command, npm: npm_command)
    end

    def test_yarn_on_class_proxies_to_the_instance_version_of_call
      JsSystem.any_instance.expects(:yarn?).once
      JsSystem.yarn?(@context)
    end

    def test_yarn_check_returns_false_if_yarn_lock_missing_and_which_yarn_call_fails
      mock_yarn_check(lock_exists: false, status: stubs(success?: false))

      refute JsSystem.yarn?(@context)
    end

    def test_yarn_check_returns_false_if_yarn_lock_not_present
      mock_yarn_check(lock_exists: false, status: stubs(success?: true))

      refute JsSystem.yarn?(@context)
    end

    def test_yarn_check_returns_false_if_yarn_lock_present_but_which_yarn_call_fails
      mock_yarn_check(lock_exists: true, status: mock(success?: false))

      refute JsSystem.yarn?(@context)
    end

    def test_yarn_check_returns_true_if_yarn_lock_present_and_which_yarn_call_succeeds
      mock_yarn_check(lock_exists: true, status: mock(success?: true))

      assert JsSystem.yarn?(@context)
    end

    private

    def mock_yarn_check(status:, lock_exists:)
      CLI::Kit::System
        .expects(:capture2)
        .with('which', 'yarn')
        .returns(['v1.0.0', status])
        .once
      File
        .expects(:exist?)
        .with(File.join(@context.root, 'yarn.lock'))
        .returns(lock_exists)
        .once
    end

    def mock_kit_system(*input)
      CLI::Kit::System
        .expects(:system)
        .with(*input, chdir: @context.root)
        .returns(mock(success?: true))
        .once
    end
  end
end
