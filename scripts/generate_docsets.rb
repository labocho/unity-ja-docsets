require "sqlite3"
require "active_record"
require "fileutils"
require "shellwords"
require "json"
require "nokogiri"
require "byebug"

class Generator
  include FileUtils
  attr_reader :version, :docset, :html_dir

  def initialize(version)
    @version = version
    @docset = "docsets/Unity 3D #{version} (ja).docset"
    @html_dir = "#{docset}/Contents/Resources/Documents"
  end

  def generate
    mkdir_p "#{docset}/Contents/Resources/Documents"
    copy_documents
    generate_plist
    prepare_database(true)
  end

  def copy_documents
    # exit $?.exitstatus unless system("cp -R src/* #{"#{docset}/Contents/Resources/Documents".shellescape}")
    cp "#{docset}/Contents/Resources/Documents/StaticFiles/images/favicons/apple-touch-icon.png", "#{docset}/icon.png"

    File.write(
      "#{html_dir}/StaticFiles/css/custom.css",
      File.read("src/StaticFiles/css/custom.css") + "\n" + File.read("assets/override.css"),
    )
  end

  def generate_plist
    open("#{docset}/Contents/Info.plist", "w") do |f|
      f.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>CFBundleIdentifier</key>
            <string>Unity 3D #{version} (ja)</string>
            <key>CFBundleName</key>
            <string>Unity 3D #{version} (ja)</string>
            <key>DocSetPlatformFamily</key>
            <string>Unity 3D #{version} (ja)</string>
            <key>isDashDocset</key>
            <true/>
            <key>dashIndexFilePath</key>
            <string>Manual/index.html</string>
          </dict>
        </plist>
      XML
    end
  end

  def prepare_database(delete)
    rm "#{docset}/Contents/Resources/docSet.dsidx", force: true if delete

    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: "#{docset}/Contents/Resources/docSet.dsidx"
    )

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)
    SQL
  end
end


class ScriptReferenceIndexer
  def create_index
    create_index_by_toc
    fix_type
    index_member
  end

  def fix_link(link)
    case link
    when /^TerrainUtility\./
      "Experimental.TerrainAPI." + link
    else
      link
    end
  end

  # Struct が Class として登録されているのを修正
  def fix_type
    SearchIndex.where(type: "Class").each do |i|
      print "."

      doc = Nokogiri.parse(i.html)
      unless type_description = doc.css(".cl.mb0.left.mr10").first
        warn "Type description not found: #{i.path}"
        next
      end

      case type_description.text.strip
      when /^struct in /
        i.update(type: "Struct")
      end
    end
  end

  def index_member
    SearchIndex.all.each do |i|
      print "."

      doc = Nokogiri.parse(i.html)

      index_section(i, doc, "Static 変数", "Property")
      index_section(i, doc, "変数", "Property")
      index_section(i, doc, "コンストラクタ", "Constructor")
      index_section(i, doc, "Public 関数", "Method")
      index_section(i, doc, "Static 関数", "Method")
      index_section(i, doc, "Operator", "Operator")
      index_section(i, doc, "Events", "Event")
      index_section(i, doc, "メッセージ", "Event")
      index_section(i, doc, "デリゲート", "Delegate")
    end
  end

  def index_section(index, doc, title, type)
    if (h2 = doc.css("h2").find {|e| e.text == title })
      table = h2.next_element
      table.css("td.lbl a").each do |a|
        name = index.name + "." + a.text
        path = "ScriptReference/#{a["href"]}"
        SearchIndex.create!(
          name: name,
          type: type,
          path: path,
        )
      end
    end
  end

  def create_index_by_toc
    root = JSON.parse(File.read("#{html_dir}/ScriptReference/docdata/toc.json"))
    each_child(root) do |child, parent|
      next if child["link"] == "null"

      # https://kapeli.com/docsets#supportedentrytypes
      type = case parent["title"]
      when "Classes"
        "Class"
      when "Enumerations"
        "Enum"
      when "Interfaces"
        "Interface"
      when "Attributes"
        "Attribute"
      when "Assemblies"
        "Module"
      else
        raise "Cannot determine type: #{child["link"]}"
      end

      fixed_link = fix_link(child["link"])
      path = "ScriptReference/#{fixed_link}.html"

      unless File.exist?(File.join(html_dir, path))
        warn "Page not found: #{path}"
        next
      end

      SearchIndex.create!(
        name: fixed_link,
        type: type,
        path: path,
      )
      print "."
    end
  end

  def each_child(parent, &block)
    return unless (children = parent["children"])

    children.each do |child|
      block.call(child, parent)
      each_child(child, &block)
    end
  end

  def html_dir
    SearchIndex.html_dir
  end
end

class SearchIndex < ActiveRecord::Base
  self.table_name = "searchIndex"
  self.inheritance_column = "active_record_type"

  mattr_accessor :html_dir

  def html
    File.read(File.join(html_dir, path))
  end
end

version = ARGV.shift
generator = Generator.new(version)
# generator.prepare_database(false)
generator.generate
SearchIndex.html_dir = generator.html_dir
indexer = ScriptReferenceIndexer.new
indexer.create_index
# indexer.index_member
# exit 1
