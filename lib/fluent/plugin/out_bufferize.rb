module Fluent
  class BufferizeOutput < BufferedOutput
    Plugin.register_output('bufferize', self)

    class PosKeeper
      FILE_PERMISSION = 0644

      @@instances = {}

      def self.get(chunk)
        @@instances[chunk.unique_id] ||= PosKeeper.new(chunk)
        @@instances[chunk.unique_id]
      end

      def self.remove(chunk)
        @@instances.delete(chunk.unique_id)
      end

      def initialize(chunk)
        @id = chunk.unique_id
        @count = 0
        @chunk = chunk

        if chunk.respond_to? :path
          @path = chunk.path +  ".pos"
          mode = File::CREAT | File::RDWR
          perm = FILE_PERMISSION
          @io = File.open(@path, mode, perm)
          @io.sync = true
          line = @io.gets
          @count = line ? line.to_i : 0
          @type = :file
        else
          @type = :mem
        end
      end

      def each(&block)
        @chunk.open do |io|
          u = MessagePack::Unpacker.new(io)
          begin
            if @count > 0
              $log.debug "Bufferize: skip first #{@count} messages" 
              @count.times do
                u.skip
              end
            end

            loop do
              tag, time, record = u.read
              yield(tag, time, record)
              increment
            end

          rescue EOFError
          end
        end
        remove
      end

      def increment
        @count += 1
        if @type == :file
          @io.seek(0, IO::SEEK_SET)
          @io.puts(@count)
        end
      end

      def remove
        if @type == :file
          @io.close unless @io.closed?
          File.unlink(@path)
        end
      end      
    end


    attr_reader :output

    def initialize
      super
    end

    def configure(conf)
      super

      configs = conf.elements.select{|e| e.name == 'config'}
      if configs.size != 1
        raise ConfigError, "Befferize: just one <config> directive is required"
      end

      type = configs.first['type']
      unless type
        raise ConfigError, "Befferize: 'type' parameter is required in <config> directive"
      end

      @output = Plugin.new_output(type)
      @output.configure(configs.first)
    end

    def start
      super
      @output.start
    end

    def shutdown
      @output.shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      PosKeeper.get(chunk).each { |tag, time, record |
        @output.emit(tag, OneEventStream.new(time, record), NullOutputChain.instance)
      }
      PosKeeper.remove(chunk)
    end
  end
end
