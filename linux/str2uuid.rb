require 'digest/md5'

ARGV.each do |arg|
    hash = Digest::MD5.hexdigest(arg)
    str = "%s-%s-4%s-a%s-%s" % [ hash[0..7], hash[8..11], hash[13..15], hash[17..19], hash[20..31] ]
    puts str + "\n"
end
