
ARGV.each do |arg|
    ipa = arg.split(".")
    result = []
    for octet in ipa do
        int = octet.to_i
        hex = int.to_s(16).upcase
        hexs = hex.rjust(2, '0')
        result << hexs
    end
    puts "00:00:" + result.join(":") + "\n"
end
