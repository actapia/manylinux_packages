# frozen_string_literal: true

require 'json'
require 'optparse'
require 'set'
require 'date'

def main
  options = {}
  OptionParser.new do |opts|
    opts.on('-u', '--url URL', 'Replacement root URL.') do |v|
      options[:root_url] = v
    end
  end.parse!
  bottle_check_fields = %w[cellar]
  bottle_check_fields.append('root_url') unless options.key?(:root_url)
  jsons = []
  ARGV.each do |path|
    jsons.append(JSON.parse(File.read(path)))
  end
  # Verify we only have one top-level key.
  top_keys = Set[]
  jsons.each do |json|
    json.each_key do |key|
      top_keys.add(key)
    end
  end
  abort("Bottles don't share the same package ID.") if top_keys.size > 1
  package_id = top_keys.to_a[0]
  # Verify that we are using only one formula.
  merged = { package_id => { 'formula' => jsons[0][package_id]['formula'] } }
  jsons[1..].each do |json|
    if json[package_id]['formula'] != merged[package_id]['formula']
      abort("Bottles don't share the same formula hash.")
    end
  end
  # Add bottle stuff.
  merged[package_id]['bottle'] = jsons[0][package_id]['bottle'].clone
  recent_date = DateTime.parse(merged[package_id]['bottle']['date'])
  jsons[1..].each do |json|
    bottle_check_fields.each do |field|
      if json[package_id]['bottle'][field] != \
         merged[package_id]['bottle'][field]
        abort("Bottles don't share the same bottle field #{field}.")
      end
    end
    if options.key?(:root_url)
      merged[package_id]['bottle']['root_url'] = options[:root_url]
    end
    new_date = DateTime.parse(json[package_id]['bottle']['date'])
    recent_date = [recent_date, new_date].min
    merged[package_id]['bottle']['rebuild'] = [
      merged[package_id]['bottle']['rebuild'],
      json[package_id]['bottle']['rebuild']
    ].min
    json[package_id]['bottle']['tags'].each do |tag, data|
      if merged[package_id]['bottle']['tags'].key?(tag)
        abort("Duplicate tag #{tag}.")
      end
      merged[package_id]['bottle']['tags'][tag] = data
    end
  end
  puts(JSON.pretty_generate(merged))
end

main if __FILE__ == $PROGRAM_NAME
