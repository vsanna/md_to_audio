class Paragraph
  attr_accessor :sentences

  def initialize(body)
    self.sentences = build_sentences(body)
  end

  def call
    # sentenceが空ならsleepもなし
    return if sentences.size == 0
    sleep 1 # TODO: option化
    sentences.each(&:call)
  end

  private

  def build_sentences(body)
    body.split("\n").map do |sentence_body|
        next if blank?(sentence_body)
        next if comment_out?(sentence_body)
        Sentence.new(sentence_body)
    end.compact
  end

  def blank?(raw_body)
    raw_body.length == 0
  end

  def comment_out?(raw_body)
    raw_body[0] == '#'
  end
end

class Sentence
  attr_accessor :body

  def initialize(body)
    self.body = body
  end

  def call
    puts body  # TODO: option化
    sleep 0.3  # TODO: option化
    say_command = "say #{body}"
    system(say_command)
    say_command_with_output_option = "#{say_command} -o ./audios/#{Time.new.to_i}.mp4" # TODO: ディレクトリ構成
    system(say_command_with_output_option) rescue nil
  end
end


class SayClient
  attr_accessor :options
  attr_accessor :script_file
  attr_accessor :paragraphs

  attr_accessor :audios

  def initialize(argv)
    self.script_file = parse_script_file(argv)
    self.options     = parse_options(argv)
    self.audios      = []

    build_paragraphs
  end

  def say
    clear_audios
    paragraphs.each(&:call)
    concat_audios
  end

  private

  def clear_audios
    audio_files.each do |filename|
      File.delete(filename)
    end
  end

  def concat_audios
    options = [
      audio_files.map { |filename| "-i #{filename} -i ./assets/blank.mp4" },
      "-filter_complex \"concat=n=#{audio_files.size}:v=0:a=1\""
    ]
    cmd = "ffmpeg #{options.join(" ")} dst.mp4"
    puts cmd
    system(cmd)
  end

  def audio_files
    Dir.glob("./audios/*")
  end

  # say.rbのある場所と同じ階層にある想定
  # thor入れたほうが楽だが使い捨てなので省略
  # @TODO: validationかける
  def parse_script_file(argv)
    "./#{argv[0]}"
  end

  # thor入れたほうが楽だが使い捨てなので省略. each_with_objectも見送り
  # @TODO: validationかける
  def parse_options(argv)
    return [] if argv.size == 1
    result = {}
    argv.each.with_index(1) do |option|
      key, val = options.split('=')
      result[key] = val
    end
    result
  end

  def build_paragraphs
    self.paragraphs = []
    File.open(script_file) do |file|
      file.read.split("====").map do |raw_body|
        body = trimmed_body(raw_body)
        next if blank?(body)
        paragraphs << Paragraph.new(body)
      end
    end
  end

  def trimmed_body(raw_body)
    raw_body.gsub(" ", "")
  end

  def blank?(raw_body)
    raw_body.length == 0
  end

  class << self
    # ffmpegが必要
    def available?
      true
    end
  end
end



# TODO:
# 利用可能かチェック

raise StandardError unless SayClient.available?

client = SayClient.new(ARGV)
client.say
