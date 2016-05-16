require 'open-uri'

def download_resource(uri, filename)
    if filename.nil? || filename.strip.empty?
        filename = uri.split(/[\/]/)[-1].split('?')[0]
    end
    puts filename
    stream   = open(uri)
    File.open(filename, 'w+b') do |file|
        stream.respond_to?(:read) ? IO.copy_stream(stream, file) : file.write(stream)
        open(file)
    end
end