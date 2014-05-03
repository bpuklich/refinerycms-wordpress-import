require 'wordpress'

namespace :wordpress do

  BLOG_TABLES  = %w(ActsAsTaggableOn::Tag Refinery::Blog::Post)
  CMS_TABLES   = %w(Refinery::Page)
  MEDIA_TABLES = %w(Refinery::Image Refinery::Resource)

# ------------------------------------- Begin blog processing tasks --------------------------------------------------
 desc 'Reset the blog tables for a clean import'
  task :reset_blog do
    Rake::Task['environment'].invoke
    clear_tables(BLOG_TABLES)
  end


  desc "import blog data from a Refinery::WordPress XML dump"
  task :import_blog, :file_name do |task, params|
    Rake::Task["environment"].invoke

    if params[:file_name].nil?
      raise "Please specifiy file_name as a rake parameter (use [filename] after task_name...)"
    end

    dump = Refinery::WordPress::Dump.new(params[:file_name])

    puts "Importing #{dump.authors.count} authors ..."
    dump.authors.each(&:to_refinery)

    only_published =         ENV['ONLY_PUBLISHED'].present?
    allow_duplicate_titles = ENV['ALLOW_DUPLICATES'].present?
    dump.posts(only_published).each do |p|
      puts "Importing page #{p.title}"
      p.to_refinery(allow_duplicate_titles)
    end
    Refinery::WordPress::Post.create_blog_page_if_necessary
  end

  desc 'Reset blog tables and then import blog data from a Refinery::WordPress XML dump'
  task :reset_and_import_blog, :file_name do |task, params|
    Rake::Task['environment'].invoke
    Rake::Task['wordpress:reset_blog'].invoke
    Rake::Task['wordpress:import_blog'].invoke(params[:file_name])
  end
# ------------------------------------- End blog processing tasks ----------------------------------------------------

# ------------------------------------- Begin CMS processing tasks ---------------------------------------------------

  desc 'Reset the CMS relevant tables for a clean import'
  task :reset_pages, :id_offset do |task, params|
    Rake::Task['environment'].invoke
    params.with_defaults :id_offset => 0
    clear_tables(CMS_TABLES, :id_offset)
  end

  desc 'Import CMS data from a WordPress XML dump'
  task :import_pages, [:file_name, :id_offset, :page_parent] do |task, params|

    params.with_defaults :id_offset => 0
    params.with_defaults :page_parent => 'blog'
    offset = params[:id_offset].to_i

    Rake::Task['environment'].invoke

    dump = Refinery::WordPress::Dump.new(params[:file_name])
    only_published = ENV['ONLY_PUBLISHED'].present?
    shortcode_setup()

    puts "Importing #{dump.pages(only_published).count} #{only_published ? 'published' : '(all)'} pages"
    dump.pages(only_published).each do |p|
      p.to_refinery(offset)
    end
#   Create the parent page for the blog pages
    Refinery::WordPress::Post.create_page_if_necessary(params[:page_parent])

    # After all pages are persisted we can now create the parent - child
    # relationships. This is necessary, as WordPress doesn't dump the pages in
    # a correct order.
    puts 'Linking pages to their parents'
    default_parent_page_id = Refinery::Page.where('link_url = ?', "/#{params[:page_parent]}").first.id
    dump.pages(only_published).each do |dump_page|
      page = Refinery::Page.find(dump_page.post_id + offset)
      page.parent_id = dump_page.parent_id ?  dump_page.parent_id + offset : default_parent_page_id
      page.save!
    end
  end
  desc 'Reset CMS tables and then import CMS data from a WordPress XML dump'
  task :reset_and_import_pages, :file_name, :page_id_start do |task, params|
    Rake::Task['environment'].invoke
    Rake::Task['wordpress:reset_pages'].invoke
    Rake::Task['wordpress:import_pages'].invoke(params[:file_name], params[:id_offset], params[:page_parent])
  end

# ------------------------------------- End page processing tasks ----------------------------------------------------

# ------------------------------------- Begin media processing tasks -------------------------------------------------

  desc 'Reset the media tables for a clean import'
  task :reset_media do
    Rake::Task['environment'].invoke
    clear_tables(MEDIA_TABLES)
  end

  desc 'Import media data (images and files) from a WordPress XML dump and replace target URLs in pages and posts'
  task :import_and_replace_media, :file_name do |task, params|
    Rake::Task['environment'].invoke
    dump = Refinery::WordPress::Dump.new(params[:file_name])

    puts 'Importing images and resources'
    attachments = dump.attachments.each(&:to_refinery)

    # parse all created BlogPost and Page bodys and replace the old wordpress media urls
    # with the newly created ones
    puts 'Linking images and resources to posts and pages'
    attachments.each do |attachment|
      attachment.replace_url
    end
  end

  desc 'Reset media tables and then import media data from a WordPress XML dump'
  task :reset_import_and_replace_media, :file_name do |task, params|
    Rake::Task['environment'].invoke
    Rake::Task['wordpress:reset_media'].invoke
    Rake::Task['wordpress:import_and_replace_media'].invoke(params[:file_name])
  end
# ------------------------------------- End media processing tasks ---------------------------------------------------

  desc 'Reset and import all data (see the other tasks)'
  task :full_import, :file_name do |task, params|
    Rake::Task['environment'].invoke
    Rake::Task['wordpress:reset_and_import_blog'].invoke(params[:file_name])
    Rake::Task['wordpress:reset_and_import_pages'].invoke(params[:file_name], params[:id_offset], paras[:page_parent])
    Rake::Task['wordpress:reset_import_and_replace_media'].invoke(params[:file_name])
  end
# ------------------------------------- End full import task ---------------------------------------------------------

# ------------------------------------- Little utilities -------------------------------------------------------------

  def clear_tables(tables, offset=0)
    tables.each do |table_name|
      # deletes dependent records as well.
      puts "Deleting records from #{table_name} ..."
      table_name.constantize.where('id>?', offset).destroy_all

    end
  end

# ------------------------------------- End little utilities ----------------------------------------------------
end
