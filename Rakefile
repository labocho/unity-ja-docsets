SRC = "https://storage.googleapis.com/localized_docs/ja/2018.4/UnityDocumentation.zip"
VERSION = "2018.4"

require "open3"

def run(*args)
  o, e, s = Open3.capture3(*args)
  unless s.success?
    $stderr.puts e
    exit s.to_i
  end
  o
end

def revision
  @revision ||= begin
    File.exist?("zip/REVISION") ? File.read("zip/REVISION").strip : ""
  end
end

task "zip" do
  if File.exist?("zip/UnityDocumentation.zip") && File.exist?("zip/REVISION")
    latest_etag = run("curl -I --silent #{SRC} 2>&1 | grep etag: | awk '{ print $2 }'").strip
    current_etag = File.read("zip/REVISION").strip
    next if latest_etag == current_etag
  end

  mkdir_p "zip"
  sh "curl #{SRC} > zip/UnityDocumentation.zip"
  sh "curl -I --silent #{SRC} 2>&1 | grep etag: | awk '{ print $2 }' > zip/REVISION"
end

task "src" => "zip" do
  next if File.exist?("src/REVISION") && File.read("src/REVISION").strip == revision

  mkdir_p "src"
  sh "unzip zip/UnityDocumentation.zip -d src"
  File.write("src/REVISION", revision)
end

task "add_original_url" => "src" do
  warn "TODO"
end

task "docsets" => "add_original_url" do
  # next if File.exist?("docsets/REVISION") && File.read("docsets/REVISION").strip == revision

  mkdir_p "docsets"
  ruby "scripts/generate_docsets.rb #{VERSION}"
  File.write("docsets/REVISION", revision)
end

task "install" => "docsets" do
  source = "docsets/Unity 3D #{VERSION} (ja).docset"
  dest = "#{ENV["HOME"]}/Library/Application Support/Dash/DocSets/Unity_3D-ja"
  rm_rf File.join(dest, File.basename(source))
  mkdir_p dest
  cp_r source, dest
end
