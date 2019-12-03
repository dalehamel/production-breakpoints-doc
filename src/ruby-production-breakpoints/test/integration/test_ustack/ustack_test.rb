# frozen_string_literal: true

require 'integration_helper'

# FIXME: can any of this be generalized / should the convention be encoded?
class UstackTest < IntegrationTestCase
  def test_ustack
    target = command('bundle exec ruby ustack.rb', wait: 1)
    tracer = TraceRunner.trace('-p', target.pid, script: 'ustack', wait: 2)

    # Signal the target to trigger probe firing
    target.usr2(2)

    assert_tracer_output(tracer.output, read_probe_file('ustack.out'))
  end
end
