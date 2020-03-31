require "find"
version = ARGV.shift

def insert_url_after_html_tag(html, url)
  comment = "<!-- Online page at #{url} -->"
  html.gsub(/(<html[^>]*>)/i) { $1 + comment }
end

Dir.chdir("src/#{version}") {
  Find.find(".") {|file|
    next unless File.extname(file) == ".html"

    path = file[1..-1] # remove first .
    url = "https://docs.unity3d.com/ja/#{version}#{path}"
    print "."
    File.write(file, insert_url_after_html_tag(File.read(file), url))
  }
}
