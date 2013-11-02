require 'helper'

class BufferizeOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp')
  end

  def teardown
    FileUtils.mkdir_p('tmp')
  end

  BASE_CONFIG = %[
type bufferize
]
  CONFIG_NO_CONFIG = BASE_CONFIG
  CONFIG_NO_TYPE = BASE_CONFIG + %[
<config>
</config>
]
  CONFIG_WITH_TYPE = BASE_CONFIG + %[
<config>
  type test
</config>
]

  def create_driver(conf = CONFIG_WITH_TYPE, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::BufferizeOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      create_driver(CONFIG_NO_CONFIG)
    }
    assert_raise(Fluent::ConfigError) {
      create_driver(CONFIG_NO_TYPE)
    }
    assert_nothing_raised(Fluent::ConfigError) {
      create_driver(CONFIG_WITH_TYPE)
    }
  end

  def create_resend_test_driver(conf = CONFIG_WITH_TYPE, tag='test')
    output = Fluent::Plugin.new_output('test')
    output.configure('name' => 'output')
    output.define_singleton_method(:start) {}
    output.define_singleton_method(:shutdown) {}
    output.define_singleton_method(:emit) do |tag, es, chain|
      @count ||= 0
      es.each do |time, record|
        @count += 1
        raise if (@count % 3) == 0
        super(tag, [[time, record]], chain)
      end
    end

    d = create_driver
    d.instance.instance_eval { @output = output }
    d
  end  

  def test_resend_with_memory_buffer
    d = create_resend_test_driver

    time = Time.parse("2013-11-02 12:12:12 UTC").to_i
    entries = []
    1.upto(5) { |i|
      entries << [time, {"a"=>i}]
    }

    es = Fluent::ArrayEventStream.new(entries)
    buffer = d.instance.format_stream('test', es)
    chunk = Fluent::MemoryBufferChunk.new('', buffer)

    assert_raise(RuntimeError) {
      d.instance.write(chunk)
    }
    assert_equal [
      {"a"=>1}, {"a"=>2},
    ], d.instance.output.records

    assert_raise(RuntimeError) {
      d.instance.write(chunk)
    }
    assert_equal [
      {"a"=>1}, {"a"=>2}, {"a"=>3}, {"a"=>4},
    ], d.instance.output.records

    assert_nothing_raised(RuntimeError) {
      d.instance.write(chunk)
    }
    assert_equal [
      {"a"=>1}, {"a"=>2}, {"a"=>3}, {"a"=>4}, {"a"=>5},
    ], d.instance.output.records
  end

  def test_resend_with_file_buffer
    d = create_resend_test_driver(CONFIG_WITH_TYPE + %[
buffer_type file
])

    time = Time.parse("2013-11-02 12:12:12 UTC").to_i
    entries = []
    1.upto(5) { |i|
      entries << [time, {"b"=>i}]
    }

    es = Fluent::ArrayEventStream.new(entries)
    buffer = d.instance.format_stream('test', es)
    chunk = Fluent::MemoryBufferChunk.new('', buffer)

    es = Fluent::ArrayEventStream.new(entries)
    chunk = Fluent::FileBufferChunk.new('', './tmp/test_buffer', 'xyz', "a+", nil)
    chunk << d.instance.format_stream('test', es)
    pos_file_path = "#{chunk.path}.pos"

    assert_raise(RuntimeError) {
      d.instance.write(chunk)
    }
    assert_equal [
      {"b"=>1}, {"b"=>2},
    ], d.instance.output.records
    assert File.exists?(pos_file_path)
    assert_equal `head #{pos_file_path}`.chomp.to_i, 2

    assert_raise(RuntimeError) {
      d.instance.write(chunk)
    }
    assert_equal [
      {"b"=>1}, {"b"=>2}, {"b"=>3}, {"b"=>4},
    ], d.instance.output.records
    assert File.exists?(pos_file_path)
    assert_equal `head #{pos_file_path}`.chomp.to_i, 4

    assert_nothing_raised(RuntimeError) {
      d.instance.write(chunk)
    }
    assert_equal [
      {"b"=>1}, {"b"=>2}, {"b"=>3}, {"b"=>4}, {"b"=>5},
    ], d.instance.output.records
    assert !File.exists?(pos_file_path)
  end

end
