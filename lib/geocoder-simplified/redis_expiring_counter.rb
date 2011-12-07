

=begin

WARNING: This class will wipe one Redis database per counter

Note:
  If you need more counters, this can easily be extended to use multiple databases
  through @@db_config.

  A note on speed: A key search based method is about ten times slower than using dbsize.

  :host       remote ip, default is 127.0.0.1
  :port       default is 6379
  :password   if you require a password on connection
  :db         default is 0
  :timeoeut   default is 5 seconds
  :logger     to log activity as database it works

Persistance:
  The counters will live on across sessions unless explicitly deleted.

Speed Improment Note:
  Let time_frame be the span of time winin which we are limiting some action (say one day for example).
  Let time_chunk be a timespan (5 minutes for instance).
  Let each time_chunk be a counter with an expiration.
  Let chunk_count be the number of time_chunks that will fit entirely within time frame.
  v = sum(time_chunk[i].count)

  We note that this method can work within an existing DB without issue.
=end

class RedisExpiringCounter
  $:.push File.expand_path("..", __FILE__)

  require 'redis'
  require 'configuration'

  attr_reader :name

  def initialize(name, expiration_in_seconds, max_count)
    @name = name
    @expiration_in_seconds = expiration_in_seconds
    @max_count = max_count

    @id_key, @db_index = get_key_and_id(name)
    @@db_0.incr(@id_key)
    @db = Redis.new({:db => @db_index, :host => Configuration::HOST, :port => Configuration::DB_PORT})
  end

  def get_free_db_id
    id = nil
    counter_list = @@db_0.keys("#{@@id_key_base}:*")
    db_id_list = counter_list.map{|k| k.split(':').last.to_i}
    if db_id_list.count == 0
      id = Configuration::FIRST_COUTER_DB_ID
    else
      @@db_range.each do |i|
        if db_id_list.index(i).nil?
          id = i
          break
        end
      end
    end
    raise @@max_count_exceeded if id.nil?
    id
  end

  def get_key_and_id(name)
    existing_counter = @@db_0.keys("#{@@id_key_base}:#{name}:*")
    raise "More than one '#{name}' counter!" if existing_counter.count > 1

    if existing_counter.count == 1
      counter_db_id = existing_counter.first.split(':').last.to_i
    elsif existing_counter.count == 0
      counter_db_id = get_free_db_id
    else
      raise "key error!"
    end

    return ["#{@@id_key_base}:#{name}:#{counter_db_id}", counter_db_id]
  end

  def increment
    if @db.dbsize < @max_count
      key = @@db_0.incr(@id_key)
      @db.setex(key, @expiration_in_seconds, '1')
      true
    else
      false
    end
  end

  def count
    @db.dbsize
  end

  def delete
    @@db_0.del(@id_key)
    @db.flushdb
  end

  def dump
    puts "database #{@db_index}:"
    keys = @db.keys
    if keys.size > 0
      values = @db.mget(*keys)
      list = Hash[keys.zip(values)]
      list.each{|k, v| puts "%s = %s" % [k, v]}
    end
  end

  class << self
    @@id_key_base = "expiring:counter"
    @@db_0 = Redis.new({:db => 0, :host => Configuration::HOST, :port => Configuration::DB_PORT})
    @@db_range = (Configuration::FIRST_COUTER_DB_ID..Configuration::LAST_COUNTER_DB_ID)
    @@id_key_list = (0..Configuration::LAST_COUNTER_DB_ID).each.map{|i| "expiring:counter:#{i}"}
    @@max_count_exceeded = <<-MARK_TEXT
      Exceeded maximum number of expiring counters (#{Configuration::MAX_COUNTER_COUNT}) in #{self.class.to_s}.
      Don't forget to call delete when a counter is no longer in use.
    MARK_TEXT


    def exists(name)
      (@@db_0.keys("#{@@id_key_base}:#{name}:*").count > 0)
    end
    def delete(db_id)
      @@db_0.del(@@db_0.keys("#{@@id_key_base}:#{name}:*").first)
    end
    def delete_all_counters
      @@db_range.each do |i|
        if @@db_0.exists(@@id_key_list[i])
          @@db_0.del(@@id_key_list[i])
        end
      end
    end
  end
end






























class RedisExpiringCounter2
  $:.push File.expand_path("..", __FILE__)

  require 'redis'
  require 'configuration'

  attr_reader :name

  def initialize(name, expiration_in_seconds, max_count, segment_count=Configuration::NUMBER_OF_SEGMENTS)
    @name = name
    @segment_length = expiration_in_seconds / segment_count
    @expiration_in_seconds = (expiration_in_seconds + @segment_length).round
    @max_count = max_count
    @base = "#{@@counter_root}:#{@name}"
    @base_lookup = "#{@base}:*"
  end

  def increment
    if count < @max_count
      block_number = Integer(Time.now.to_f / @segment_length)
      segment_key = "#{@base}:#{block_number}"
      if not @@db_0.exists(segment_key)
        @@db_0.setex(segment_key, @expiration_in_seconds, '1')
      else
        @@db_0.incr(segment_key)
      end
      true
    else
      false
    end
  end

  def count()
    key_list = @@db_0.keys(@base_lookup)
    if key_list.size > 0
      @@db_0.mget(*key_list).inject(0){|sum, n| sum + n.to_i}
    else
      0
    end
  end

  def delete
    key_list = @@db_0.keys(@base_lookup)
    @@db_0.del(*key_list) if key_list.size > 0
  end

  def dump
    puts "database #{@base_lookup}:"
    keys = @@db_0.keys(@base_lookup)
    if keys.size > 0
      values = @db.mget(*keys)
      list = Hash[keys.zip(values)]
      list.each{|k, v| puts "%s = %s" % [k, v]}
    end
  end

  class << self
    @@counter_root = "expiring:counter"
    @@db_0 = Redis.new({:db => 0, :host => Configuration::HOST, :port => Configuration::DB_PORT})
    @@db_range = (Configuration::FIRST_COUTER_DB_ID..Configuration::LAST_COUNTER_DB_ID)
    @@id_key_list = (0..Configuration::LAST_COUNTER_DB_ID).each.map{|i| "expiring:counter:#{i}"}
    @@max_count_exceeded = <<-MARK_TEXT
      Exceeded maximum number of expiring counters (#{Configuration::MAX_COUNTER_COUNT}) in #{self.class.to_s}.
      Don't forget to call delete when a counter is no longer in use.
    MARK_TEXT
  end
end








if __FILE__ == $0 # if this file is being executed directly, run this code

  def dump_database(db)
    puts "-" * 76
    puts "database dump:"
    keys = db.keys
    if keys.size > 0
      values = db.mget(*keys)
      list = Hash[keys.zip(values)]
      list.each{|k, v| puts "%s = %s" % [k, v]}
    end
  end

  def float_with_commas(n, decimal_places)
    whole = Integer(n)
    fraction = n - whole
    decimal_format = "%%.%df" % decimal_places
    whole.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse << (decimal_format % fraction)[1..-1]
  end

  duration_of_limit_in_seconds = 3
  segment_count = 3
  google_max_calls_per_day = 14
  yahoo_max_calls_per_day = 10

  Redis.new.flushall
  #require 'pry'

  # puts "Make google counter..."
  # google_counter = RedisExpiringCounter2.new("google", duration_of_limit_in_seconds, google_max_calls_per_day, segment_count)
  #
  # puts "Make yahoo counter..."
  # yahoo_counter = RedisExpiringCounter2.new("yahoo", duration_of_limit_in_seconds, yahoo_max_calls_per_day, segment_count)
  #
  # p google_counter.inspect
  # p yahoo_counter.inspect
  #
  # 20.times do
  #   if google_counter.increment
  #     # call google api
  #   end
  #   sleep 0.07
  # end
  #
  # 10.times do
  #   if yahoo_counter.increment
  #     # call yahoo api
  #   end
  #   sleep 0.15
  # end
  #
  # 7.times do
  #   puts
  #   puts "g count = #{google_counter.count}"
  #   puts "y count = #{yahoo_counter.count}"
  #   sleep 0.9
  # end
  #
  # puts
  # p google_counter.inspect
  # p yahoo_counter.inspect
  # puts
  #
  # # free the counters
  # #google_counter.delete
  #
  # puts "Remove yahoo counter..."
  # yahoo_counter.delete

  require "benchmark"

  ITERATION_COUNT = 500

  dump_database(Redis.new); puts
  counter = RedisExpiringCounter.new("time-test", 23, ITERATION_COUNT)
  counter2 = RedisExpiringCounter2.new("time-test2", 23, ITERATION_COUNT)
  dump_database(Redis.new); puts

  p counter.inspect
  puts "#{ITERATION_COUNT} increments with a check on each:"

  t = nil
  t2 = nil
  Benchmark.bm do |outer_pass|
    t = outer_pass.report("count with expiration:      ") do
      ITERATION_COUNT.times do
        if counter.increment
          # call api
        end
      end
    end
    t2 = outer_pass.report("count with expiration fast: ") do
      ITERATION_COUNT.times do
        if counter2.increment
          # call api
        end
      end
    end
  end

  ms_per_call = ((t.real * 1000.0) / ITERATION_COUNT)
  ms_per_call2 = ((t2.real * 1000.0) / ITERATION_COUNT)
  calls_per_second = Integer(1000.0 / ms_per_call)
  calls_per_second2 = Integer(1000.0 / ms_per_call2)
  puts
  p counter.inspect
  #puts "#{ms_per_call}ms per call."
  puts "#{calls_per_second} calls per second."
  puts "#{calls_per_second2} calls per second."

end






