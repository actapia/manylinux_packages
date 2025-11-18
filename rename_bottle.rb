# frozen_string_literal: true

require 'json'

def main
  json_file = JSON.parse(File.read(ARGV[0]))
  json_file.each_value do |package|
    package['bottle']['tags'].each_value do |bottle|
      File.rename(bottle['local_filename'], bottle['filename'])
    end
  end
end

main if __FILE__ == $PROGRAM_NAME
