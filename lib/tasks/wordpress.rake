require 'wordpress'

namespace :wordpress do

  BLOG_TABLES  = %w(ActsAsTaggableOn::Tag Refinery::Blog::Post Refinery::Blog::Category)
  CMS_TABLES   = %w(Refinery::Page)
  MEDIA_TABLES = %w(Refinery::Image Refinery::Resource)

# ------------------------------------- Begin blog processing tasks --------------------------------------------------
 desc 'Reset the blog tables for a clean import'
  task :reset_blog => :environment do
    # init
    clear_tables(BLOG_TABLES)
  end

  desc "Import categories from a Refinery::WordPress XML dump"
  task :import_categories, [:file_name] => [:environment] do |task, params|
    # init
    dump = Refinery::WordPress::Dump.new(params.file_name)
    puts_unless_silent "Importing #{dump.categories.count} categories ..."
    dump.categories.each(&:to_refinery)
  end

  desc "Import tags from a Refinery::WordPress XML dump"
  task :import_tags, [:file_name] => [:environment] do |task, params|
    # init
    dump = Refinery::WordPress::Dump.new(params.file_name)
    puts_unless_silent "Importing #{dump.tags.count} tags ..."
    dump.tags.each(&:to_refinery)
  end

  desc "Import blog data from a Refinery::WordPress XML dump"
  task :import_blog, [:file_name] => [:environment] do |task, params|
    # init
    dump = Refinery::WordPress::Dump.new(params.file_name)

    puts_unless_silent "Importing #{dump.authors.count} authors ..."
    dump.authors.each(&:to_refinery)

    only_published =         ENV['ONLY_PUBLISHED'].present?
    allow_duplicate_titles = ENV['ALLOW_DUPLICATES'].present?
    puts_unless_silent "Importing #{dump.posts(only_published).count} #{only_published ? 'published' : '(all)'} posts"
    puts_unless_silent "Duplicate titles #{allow_duplicate_titles ? '' : 'not '}allowed."
    dump.posts(only_published).each do |p|
      puts_unless_silent "Importing post #{p.title}"
      p.to_refinery(allow_duplicates: allow_duplicate_titles)
    end
    Refinery::WordPress.create_page_if_necessary('blog')
  end

  desc 'Reset blog tables and then import blog data from a Refinery::WordPress XML dump'
  task :reset_and_import_blog, [:file_name] do |task, params|
    Rake::Task['wordpress:reset_blog'].invoke
    Rake::Task['wordpress:import_blog'].invoke(params.file_name)
  end
# ------------------------------------- End blog processing tasks ----------------------------------------------------

# ------------------------------------- Begin CMS processing tasks ---------------------------------------------------

  desc 'Reset the CMS relevant tables for a clean import'
  task :reset_pages, [:id_offset] => [:environment] do |task, params|
    # Rake::Task['environment'].invoke
    params.with_defaults :id_offset => 0
    clear_tables(CMS_TABLES, params.id_offset.to_i)
  end

  desc 'Import CMS data from a WordPress XML dump'
  task :import_pages, [:file_name, :id_offset, :page_parent] => [:environment] do |task, params|
    # init
    dump = Refinery::WordPress::Dump.new(params.file_name)
    params.with_defaults :id_offset => 0
    params.with_defaults :page_parent => 'blog'
    offset = params.id_offset.to_i

    only_published = ENV['ONLY_PUBLISHED'].present?
    puts_unless_silent "Importing #{dump.pages(only_published).count} #{only_published ? 'published' : '(all)'} pages"
    dump.pages(only_published).each do |p|
      p.to_refinery(offset)
    end
#   Create the parent page for the blog pages
    Refinery::WordPress.create_page_if_necessary(params.page_parent)

    # After all pages are persisted we can now create the parent - child
    # relationships. This is necessary, as WordPress doesn't dump the pages in
    # a correct order.
    puts_unless_silent 'Linking pages to their parents'
    default_parent_page_id = Refinery::Page.by_slug(params.page_parent).first.id
    dump.pages(only_published).each do |dump_page|
      page = Refinery::Page.find(dump_page.post_id + offset)
      page.parent_id = dump_page.parent_id ?  dump_page.parent_id + offset : default_parent_page_id
      page.save!
    end
  end

  desc 'Reset CMS tables and then import CMS data from a WordPress XML dump'
  task :reset_and_import_pages, [:file_name, :id_offset, :page_parent] => [:environment] do |task, params|
    Rake::Task['wordpress:reset_pages'].invoke(params.id_offset)
    Rake::Task['wordpress:import_pages'].invoke(params.file_name,params.id_offset,params.page_parent)
  end

# ------------------------------------- End page processing tasks ----------------------------------------------------

# ------------------------------------- Begin media processing tasks -------------------------------------------------

  desc 'Reset the media tables for a clean import'
  task :reset_media, [:id_offset] => [:environment] do |task, params|
    # Rake::Task['environment'].invoke
    params.with_defaults :id_offset => 0
    clear_tables(MEDIA_TABLES, params.id_offset.to_i)
  end

  desc 'Import media data (images and files) from a WordPress XML dump and replace target URLs in pages and posts'
  task :import_media, [:file_name] => [:environment] do |task, params|
    # init
    dump = Refinery::WordPress::Dump.new(params.file_name)

    puts_unless_silent 'Importing images and resources'
    attachments = dump.attachments.each(&:to_refinery)

    # parse all created BlogPost and Page bodys and replace the old wordpress media urls
    # with the newly created ones
    puts_unless_silent 'Linking images and resources to posts and pages'
    attachments.each do |attachment|
      attachment.replace_url
    end
  end

  desc 'Reset media tables and then import media data from a WordPress XML dump'
  task :reset_and_import_media, [:file_name, :id_offset] do |task, params|
    Rake::Task['wordpress:reset_media'].invoke(params.id_offset)
    Rake::Task['wordpress:import_media'].invoke(params.file_name)
  end
# ------------------------------------- End media processing tasks ---------------------------------------------------

  desc 'Reset and import all data (see the other tasks)'
  task :full_import, [:file_name, :page_id_offset, :page_parent, :media_id_offset] do |task, params|
    Rake::Task['wordpress:reset_and_import_blog'].invoke(params.file_name)
    Rake::Task['wordpress:reset_and_import_pages'].invoke(params.file_name,params.page_id_offset,params.page_parent)
    Rake::Task['wordpress:reset_and_import_media'].invoke(params.file_name,params.media_id_offset)
  end
# ------------------------------------- End full import task ---------------------------------------------------------

# ------------------------------------- utilities -------------------------------------------------------------
  def clear_tables(tables, offset=0)
    tables.each do |table_name|
      # deletes dependent records as well.
      puts_unless_silent "Deleting records with ids>#{offset} from #{table_name} ..."
      table_name.constantize.where('id>?', offset).destroy_all
    end
  end

  def puts_unless_silent(msg)
    puts msg unless ENV['SILENT'].present?
  end
# ------------------------------------- End utilities ----------------------------------------------------
end
