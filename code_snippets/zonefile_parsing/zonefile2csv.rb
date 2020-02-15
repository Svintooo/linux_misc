#!/usr/bin/env ruby
# Based on https://redmine.ilait.se/issues/45968#note-7
# Original author: Hugo Ankarloo
# Last udpated: 2019-03-07



#
# Help & Usage
#

if (ARGV & ["-h","--help"]).any?
  puts "Usage: zonefile2csv.rb [-D CSV_SAVE_PATH] file1 file2 file3 ..."
  puts "       zonefile2csv.rb [-D CSV_SAVE_PATH] directory"
  puts ""
  puts "NOTE: filenames must be the same as the domain name the zone is for."
  puts "      The file extension must be '.dns' or none at all."
  puts ""
  puts "This script parses zone files and converts them to CSV files."
  puts "A CSV file is stored in the same path as the original zone file,"
  puts "unless the -D parameter is set."
  exit
end



#
# Requirements
#

require "csv"



#
# Args
#

zone_files = []
args = ARGV
csv_directory = nil

while (arg = args.shift) do
  if arg == "-D" || arg == "--csv-directory"
    csv_directory = args.shift
    raise "Invalid path: #{csv_directory}" unless FileTest.directory?(csv_directory)
  elsif FileTest.directory?(arg)
    args += Dir["#{arg}/*"]
  elsif FileTest.file?(arg) and FileTest.readable?(arg)
    zone_files << arg
  end
end



#
# Convert zones to csv
#

zone_files.each do |zone_file|
  ## Init ##
  file_name = File.basename(zone_file)
  domain_name = file_name.gsub(/\.(dns)$/,'')  # Remove file extension '.dns' (if it exists)

  dns_records = []  # All parsed zone data will end up here


  ## Dump the zone file content into memory ##
  dns_records_string = File.open(zone_file){|f| f.read}.strip ; dns_records_string.length


  ## Remove unecessary information ##
  # Convert all line breaks to unix style (\r\n and \r to \n)
  dns_records_string = dns_records_string.gsub(/\r?\n|\r/,"\n") ; dns_records_string.length
  # Remove all empty lines
  dns_records_string = dns_records_string.gsub(/\n[\s]*\n/,"\n") ; dns_records_string.length
  # Remove lines that only contain a comment
  dns_records_string = dns_records_string.gsub(/^\s*;[^\n]*\n/,"") ; dns_records_string.length
  # Remove all comments
  dns_records_string = dns_records_string.gsub(/("([^"\n]*;)+[^"\n]*")|\s*;[^\n]*/, '\1') ; dns_records_string.length


  ## Parse the zone data ##
  # Default origin
  origin = domain_name + "."

  # Replace "@" with origin
  dns_records_string.gsub!(/@/, origin) ; dns_records_string.length

  # Extract the first TLL
  time_conversion_table = {
    "s" =>      1, # Second (default)
    "m" =>     60, # Minute
    "h" =>   3600, # Hour
    "d" =>  86400, # Day
    "w" => 604800, # Week
  }

  ttl = dns_records_string.slice!(/^\$ttl[^\n]*\n/i)
  ttl = "86400" unless ttl
  ttl = ttl.strip.gsub(/\$ttl\s+/i, "")
  if ttl =~ /[^0-9]/  # if ttl contains something other than numbers
    # Convert to seconds
    ttl_value, ttl_format = ttl.split(/(?=[a-z])/i)  # Ex: "30M" => "30", "M" 
    ttl = (ttl_value.to_i * time_conversion_table[ttl_format.downcase]).to_s
  end

  # Extract SOA
  soa = dns_records_string.slice!(/^[^\n]+SOA[^\n]+\([^\)]+\)\n/i)
  soa = dns_records_string.slice!(/^[^\n]+SOA[^\n]+\n/i) unless soa
  soa = soa.strip.gsub(/[\(\)]/, "").gsub(/\s+/, " ").strip

  # Convert data to Array
  dns_record_arrays = dns_records_string.split("\n").inject([]) do |array, row|
    row = row.gsub(/\s+IN\s+/, "\tIN\t")
    row = row.gsub(/\t\t+/,"\t")
    record = row.split(/\s+/)
    if record[0] =~ /^\$generate$/i
      #http://www.zytrax.com/books/dns/ch8/generate.html
      #"start-stop[/step]" => "start", "stop", "step" 
      start, stop, step = record[1].split(/[-\/]/).collect{|s| s.to_i}
      step ||= 1
      # "$[{offset[,width[,type]]}]" => "$" 
      record[2..-1].each{|string| string.gsub!(/[$][{][^}]*[}]/, "$")}
      #generate
      start.step(stop, step).each do |value|
        array << record[2..-1].collect{|string| string.gsub(/[$]/, value.to_s)}
      end
    else
      array << record
    end
    array
  end.inject([]) do |array, record|
    if record[0] =~ /^\$origin$/i
      origin = record[1] if record[1] != "." 
    elsif record[0] =~ /^\$ttl$/i
      record[0] = record[0].downcase
      array << record
    else
      record[0] = record[0].strip.gsub(/\.?$/,".#{ origin }") if record[0] != "" && !(record[0] =~ /\.$/) && !(record[0] =~ /#{ origin }$/)
      array << record
    end
    array
  end ; dns_record_arrays.count

  # Add origin to all rows that doesn't have it
  dns_record_arrays.each_index do |index|
    record = dns_record_arrays[index]
    next if record[0] != "" 
    record[0] = (index == 0) ? "#{domain_name}." : dns_record_arrays[index-1][0]
    record[0] = "#{domain_name}." if record[0] == "$ttl" 
  end.count

  # Parse the data (convert all data to a hashmap)
  dns_record_arrays.each{|record|
    record = record.clone
    if record[0] == "$ttl" 
      ttl = record[1]
      if ttl =~ /[^0-9]/  # if ttl contains something other than numbers
        #Convert to seconds
        ttl = (dt = DateTime.parse(ttl) ; dt.hour * 3600 + dt.min * 60).to_s
      end
      next
    end
    new_record = {}
    new_record[:domain_name] = domain_name
    record_name = record.shift.gsub(/\.$/, "")
    string = record.shift
    if string =~ /^[0-9]+$/
      new_record[:ttl] = string
      string = record.shift
    else
      new_record[:ttl] = ttl
    end
    new_record[:name] = record_name
    string = record.shift if string =~ /IN/i
    new_record[:record_type] = string.upcase
    if new_record[:record_type] =~ /mx|srv/i
      new_record[:prio] = record.shift
    else
      new_record[:prio] = "0"
    end
    new_record[:content] = record.join(" ")
    if ["AFSDB","CNAME","DNAME","KX","MX","NS","SRV"].include?(new_record[:record_type])
      new_record[:content] += ".#{ domain_name }" if !(new_record[:content] =~ /\.$/)
    end
    new_record[:content] = new_record[:content].gsub(/\.$/, "")
    dns_records << new_record
  } ; dns_records.count

  ## Store parsed data in CSV file ##
  csv_file_path = csv_directory ? "#{csv_directory}/#{File.basename(zone_file)}.csv"
                                : "#{zone_file}.csv"
  CSV.open(csv_file_path, "wb") do |csv|
    csv << dns_records.first.keys
    dns_records.each do |dns_record|
      csv << dns_record.values
    end
  end
end

exit



#
# Extra code which is not used
#

#
### Show 60 random dn records
#show = 60 ; if dns_records.count < show then i = 0 else i = rand( dns_records.count - show ) end ; dns_records[i...(i + show)].each{|record| puts "{:domain_name=>#{record[:domain_name].inspect.ljust(34)}, :ttl=>#{record[:ttl].inspect.ljust(7)}, :name=>#{record[:name].inspect.ljust(42)}, :record_type=>#{record[:record_type].inspect.ljust(7)}, :prio=>#{record[:prio].inspect.rjust(4)}, :content=>#{record[:content].inspect}}" }.count
#
#
### Filtrera bort records ##
#
##filtrera ut PTR-records
#removed_dns_records = dns_records.select{|record| record[:record_type] == "PTR"}
#( dns_records -= removed_dns_records ).count
#
##filtrera ut NS-records
#removed_dns_records = dns_records.select{|record| record[:record_type] == "NS"}
#( dns_records -= removed_dns_records ).count
#old_name_servers = removed_dns_records.collect{|record| record[:content]}.sort.uniq
#
#
### Fixa felaktigheter i datan ##
#
##TTL - Vi vill inte sätta den alltför lågt
#dns_records.each do |record|
#  record[:ttl] = "28800" if record[:ttl].to_i < 28800
#end.count