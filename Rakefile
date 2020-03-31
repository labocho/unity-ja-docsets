require "open3"

VERSIONS= %w(
  2019.3
  2019.2
  2019.1
  2018.4
  2018.3
  2018.2
  2018.1
  2017.4
  2017.3
  2017.2
  2017.1
  5.6
)

def version
  @version ||= begin
    v = ENV["VERSION"].to_s
    unless VERSIONS.include?(v)
      warn "VERSION environment variable is not in (#{VERSIONS.join("|")})"
      exit 1
    end
    v
  end
end

def docset_path
  @docset_path ||= "docset/Unity #{version}-ja.docset"
end

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
    File.exist?("zip/#{version}/REVISION") ? File.read("zip/#{version}/REVISION").strip : ""
  end
end

desc "List available versions"
task "versions" do
  puts VERSIONS.join("\n")
end

task "zip" do
  url = "https://storage.googleapis.com/localized_docs/ja/#{version}/UnityDocumentation.zip"

  if File.exist?("zip/#{version}/UnityDocumentation.zip") && File.exist?("zip/#{version}/REVISION")
    latest_etag = run("curl -I --silent #{url} 2>&1 | grep etag: | awk '{ print $2 }' | sed s/\\\"//g").strip
    current_etag = File.read("zip/#{version}/REVISION").strip
    next if latest_etag == current_etag
  end

  mkdir_p "zip/#{version}"
  sh "curl #{url} > zip/#{version}/UnityDocumentation.zip"
  sh "curl -I --silent #{url} 2>&1 | grep etag: | awk '{ print $2 }' | sed s/\\\"//g > zip/#{version}/REVISION"
end

task "src" => "zip" do
  next if File.exist?("src/#{version}/REVISION") && File.read("src/#{version}/REVISION").strip == revision

  mkdir_p "src/#{version}"
  sh "unzip zip/#{version}/UnityDocumentation.zip -d src/#{version}"
  File.write("src/#{version}/REVISION", revision)
end

task "add_original_url" => "src" do
  next if File.read("src/#{version}/Manual/index.html")[%(<html class="no-js" lang="ja"><!-- Online page at https://docs.unity3d.com/ja/#{version}/Manual/index.html -->)]
  ruby "scripts/add_original_url.rb #{version}"
end

desc "Build docset to ./docset/VERSION"
task "docset" => "add_original_url" do
  next if File.exist?("#{docset_path}/REVISION") && File.read("#{docset_path}/REVISION").strip == revision

  mkdir_p docset_path
  ruby "scripts/generate_docset.rb", docset_path, version
  File.write("#{docset_path}/REVISION", revision)
end

desc "Build and install docset"
task "install" => "docset" do
  dest = "#{ENV["HOME"]}/Library/Application Support/Dash/DocSets/Unity-#{version}-ja"
  rm_rf File.join(dest, File.basename(docset_path))
  mkdir_p dest
  cp_r docset_path, dest
end

task "clean" do
  rm_rf "zip"
  rm_rf "src"
  rm_rf "docset"
end

task "default" => "docset"
