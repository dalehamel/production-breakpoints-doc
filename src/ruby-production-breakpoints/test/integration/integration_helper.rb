# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/reporters'
require 'pry-byebug' if ENV['PRY']

require 'tempfile'

require 'ruby-production-breakpoints'
require 'ruby-static-tracing'

CACHED_DTRACE_PATH = File.expand_path('../../.bin/dtrace', __dir__).freeze
PIDS = []
def cleanup_pids
  PIDS.each do |p|
    Process.kill('KILL', p)
  rescue Errno::EPERM
  end
end

MiniTest.after_run { cleanup_pids }

module TraceRunner
  module_function

  def trace(*flags, script: nil, wait: nil)
    cmd = ''
    if StaticTracing::Platform.linux?
      outfile = Tempfile.new('ruby-production_bp_out')
      @path = outfile.path
      outfile.unlink

      cmd = 'bpftrace'
      cmd = [cmd, "#{script}.bt", '-o', @path] if script
    elsif StaticTracing::Platform.darwin?
      cmd = [CACHED_DTRACE_PATH, '-q']
      cmd = [cmd, '-s', "#{script}.dt"] if script
    else
      puts 'WARNING: no supported tracer for this platform'
      return
    end

    cmd = [cmd, flags]

    command = cmd.flatten.join(' ')
    CommandRunner.new(command, wait, path: @path)
  end
end

# FIXME: add a "fixtures record" helper to facilitate adding tests / updating fixtures
class CommandRunner
  TRACE_ENV_DEFAULT = {
    'BPFTRACE_STRLEN' => ProductionBreakpoints::
                                                Breakpoints::
                                                Base::MAX_USDT_STR_SIZE.to_s
  }.freeze

  attr_reader :pid, :path

  def initialize(command, wait=nil, path: path)
    puts command if ENV['DEBUG']

    unless path
      outfile = Tempfile.new('ruby-production_bp_out')
      @path = outfile.path
      outfile.unlink
    end

    if path
      @pid = Process.spawn(TRACE_ENV_DEFAULT,
                           command, out: '/dev/null', err: '/dev/null')
      @path = path
    else
      @pid = Process.spawn(TRACE_ENV_DEFAULT,
                           command, out: [@path, 'w'], err: '/dev/null')
    end

    PIDS << @pid
    sleep wait if wait
  end

  def output
    File.read(@path)
  end

  def interrupt(wait=nil)
    rc = Process.kill('INT', @pid)
    sleep wait if wait
    rc
  end

  def kill(wait=nil)
    rc = Process.kill('KILL', @pid)
    sleep wait if wait
    rc
  end

  def urg(wait=nil)
    rc = Process.kill('URG', @pid)
    sleep wait if wait
    rc
  end

  def usr2(wait=nil)
    rc = Process.kill('USR2', @pid)
    sleep wait if wait
    rc
  end
end

class IntegrationTestCase < MiniTest::Test
  def run
    file_directory = location.split('#').last
    test_dir = File.expand_path(file_directory, File.dirname(__FILE__))
    Dir.chdir(test_dir) do
      super
    end
  end

  def command(command, wait: nil)
    CommandRunner.new(command, wait)
  end

  def read_probe_file(file)
    File.read(file)
  end

  def assert_tracer_output(outout, expected_ouput)
    msg = <<~EOF
      Output from tracer:
      #{mu_pp(outout)}

      Expected output:
      #{mu_pp(expected_ouput)}
    EOF
    assert(outout == expected_ouput, msg)
  end
end

def cache_dtrace
  puts <<-eof
  In order to run integration tests on OS X, we need to run
  dtrace with root permissions. To do this, we will ask you for
  sudo access to grant SETUID to a copy of the dtrace binary that
  we will cache in this project directory.

  Once this is done, any time you run integration tests dtrace will
  run as root, but the test suite won't.

  Please enter your sudo password to continue.
  eof
  FileUtils.mkdir_p(File.dirname(CACHED_DTRACE_PATH))
  FileUtils.cp('/usr/sbin/dtrace', CACHED_DTRACE_PATH)
  system("sudo chown root #{CACHED_DTRACE_PATH} && sudo chmod a+s #{CACHED_DTRACE_PATH}")
end

if StaticTracing::Platform.darwin?
  cache_dtrace unless File.exist?(CACHED_DTRACE_PATH)
end

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]
