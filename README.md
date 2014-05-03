# Refinerycms-wordpress-import

This project imports WordPress XML dumps into refinerycms-blog.

The original repository is [https://github.com/mremolt/refinerycms-wordpress-import]
THe shortcode processing came from [https://github.com/zyphlar/wordpress-import]

Keep in mind that links to other pages of your blog are just copied, as WordPress exports them as anchors.
If your site (blog) structure uses new urls, the links WILL break! For example, if you used
the popular WP blog url structure "YYYY-MM/slug", be warned that Refinery just uses "blog/slug".
So your inner site links will point to the old WP url.


## Prerequisites

You will need an installation of refinerycms and refinerycms-blog.
Make sure the site is running, all migrations are run and you created the first refinery user.


## Installation

Add the gem to the Gemfile:

    gem 'refinerycms-wordpress-import'

and run

    bundle


## Usage

Use the Wordpress Export tool to export pages, posts, media, comments, tags and categories from your Wordpress site  to an XML file.

Importing the XML dump is done via rake tasks in three stages any of which are optional.

### Wordpress post/Refinery blog tasks

    1. rake wordpress:reset_blog
    2. rake wordpress:import_blog[file_name] _ONLY_PUBLISHED_ _ALLOW_DUPLICATES_
    3. rake wordpress:reset_and_import_blog[file_name]

The first task deletes posts from Refinery blog tables along with their associated records (taggings, tags, blog_comments, blog_categories, blog_posts, blog_categories_blog_posts).
This task is useful if you need to rerun the import process.

The second task parses the XML dump and imports blog posts, authors, comments, categories and tags into refinery tables. For more information about the content conversion process see [#conversion](Page and post conversion) below.

The *file_name* parameter is the path to the dump file.

*ONLY_PUBLISHED* and *ALLOW_DUPLICATES* are optional environment variables you can use to control the import.

To avoid importing draft posts, set the ENV variable ONLY_PUBLISHED.

To allow posts with duplicate titles set the ENV variable ALLOW_DUPLICATES.
(Refinery doesn't allow duplicate titles, so second and subsequent posts will have a post-id attached to their regular title)

__Example__ to skip all unpublished posts
    rake wordpress:import_blog[file_name] ONLY_PUBLISHED

The third task combines the two previous tasks.


### Wordpress page/Refinery page tasks

If you want to import WordPress pages three more rake tasks manage the import into RefineryCMS Pages.

    1. rake wordpress:reset_pages[offset_id]
    2. rake wordpress:import_pages[file_name, offset_id, parent] _ONLY_PUBLISHED_ _ALLOW_DUPLICATES_
    3. rake wordpress:reset_and_import_pages[file_name, offset_id, parent] _ONLY_PUBLISHED_ _ALLOW_DUPLICATES_

Parameters
_file_name_: (no default) the file name of the Wordpress XML dump file
_offset_id_: (default=0) An offset to add to the Wordpress page ids to ensure that there is no conflict with existing Refinery page.
If your highest Refinery page id is 55, you might set an offset_id of 100. (or 56)
_parent_: (no default) By default pages without a parent-id will be set to be top-level pages. To attach these pages as children of a specific page use the page slug.

The first task deletes pages from the Refinery CMS, enabling a clean import. Existing pages could break the import because of duplicate IDs.
If you have Refinery pages you wish to keep use the _offset_id_ parameter to specify a lower_limit on page_ids to be deleted.

The second task imports WordPress pages into Refinery. If an _offset_id_ has been given all pages will have the offset value added to their Wordpress page-id. The page parent-child structure is preserved. For more information about the content conversion process see [#conversion](Page and post conversion) below.

To skip unpublished pages add the ONLY_PUBLISHED parameter to this task.
To allow duplicate page titles add the ALLOW_DUPLICATES parameter to this task.

To clean and import in a single step use the third task.

Example: to import the Wordpress pages attach the imported Wordpress pages as the children of the home page. All the pages will have 100 added to their Wordpress page_ids.

    rake wordpress:import_pages[file_name, 100, 'home']

Example: import published pages with their original page-ids unchanged.

    rake wordpress:import_pages[file_name] ONLY_PUBLISHED


### Wordpress media/Refinery Image and Resource tasks
For a working media import the old site with the media URLs must still be online. The gem downloads the files from the old site and imports them into Refinery. THis step must happen after the pages and posts have been imported so that new file urls can be added to the content.

The Wordpress XML dump contains absolute links to media files linked inside posts, like:

    www.mysite.com/wordpress/wp-content/uploads/2011/05/cv.txt

The dump does NOT contain the files itself. To import them, this gem downloads the files
from the given URL and imports them to refinery.

After the files have been imported, the gem replaces the old links in pages and blog posts with the
newly generated links to the Refinery site. It parses all existing records searching for the old URLs. For this to work
you must import pages and posts FIRST to get the URLs replaced.

Now to the rake tasks for media import:

    1. rake wordpress:reset_media
    2. rake wordpress:import_and_replace_media[file_name]
    3. rake wordpress:reset_import_and_replace_media[file_name]

The first task deletes records from the Refinery media tables (Refinery::Images, Refinery::Resources)

The second task imports the Wordpress media into Refinery. This task downloads files from the old site so may take some time.
After the import it parses all pages and blog posts, replacing the old URLs with the current refinery ones.

The third task allows you to clean and import in one task.


### Importing everything
Finally, if you want to reset and import all data including media (see below):

    rake wordpress:full_import[file_name, offset_id, parent] _ONLY_PUBLISHED_ _ALLOW_DUPLICATES_


## Usage on ZSH

One more hint for users of zsh

The square brackets following the rake task need to be escaped on zsh, as they have a
special meaning there. So the syntax is:

    rake wordpress:reset_and_import_blog\[file_name\]

Ugly, but it works. This is the case for all rake tasks.

#### Page and post conversion
<a name="conversion"/>
During page and post conversion some shortcodes and other special features are recognized and changed.

__base64 encoded images__

    Some content has been notes which includes base64 encoded images. These appear as a single line of 500K or more characters which the rest of the content processing seemed to struggle with. These images are processed and saved as files in the public folder, and an appropriate url is inserted into the text.

__Shortcodes__

Shortcodes are processed using the Shortcode gem and template files located in support/templates/haml. You may wish to add to these templates for frequently occurring shortcodes in your Wordpress site.

_caption_

    [caption id="attachment_304" align="alignright" width="300" ]
         <img class="size-medium wp-image-304" title="Image Title" src="http://example.com/blog/wp-content/uploads/2011/10/image.jpg" alt="There is an image here" width="300" height="198"style="padding-left:20px" />
        Here is an image
    [/caption]

    <figure>
      <img class="size-medium wp-image-304" title="Image Title" src="image.jpg" alt="There is an image here" src="http:/refineryeg.com/dragonflystuffimage.jpg" />
      <figcaption>Here is an image</figcaption>
    </figure>

_column_

    [column width="47%" padding="0"] foo [/column]
    <div class="post_column_1">

*end_columns*

    [end_columns]
    <div style="clear: both;"></div>
_google-map-v3_

    [google-map-v3]  I don't use this shortcode and haven't tested it. It adds an iframe with a google map code.

_quote_

    [quote author="Fred Dagg"]Fair words butter no parsnips.[/quote]

    <blockquote>
      <p class='quotation'>Fair words butter no parsnips.
        <p class='citation'><span class="author">Fred Dagg</span></p>
      </p>
    </blockquote>

_ruby_

    [ruby]p "Hello Word"[/ruby]
    <pre class="brush: ruby">p "Hello world"</pre>

_youtube_

    [youtube id='youtubeid' width='300' height='400]
    [youtube youtubeid 300 400]
    <p>
      <iframe width=300 height=400 frameborders=0 type='text/html' class='youtube-player'
        src='http://www.youtube.com/embed/youtubeid?version=3&rel=1&fs=1&showsearch=0&showinfo=1&iv_load_policy=1&wmode=transparent'>
      </iframe>
    </p>

__Adding and modifying shortcode conversions__

Shortcode templates are processed by the [https://github.com/kernow/shortcode](Shortcode gem).
The gem is initialized in `lib/wordpress/page.rb` and the templates are in the directory `support/templates/haml`.
Modifying a template done by editing the template file.
To add a template you need to add its name to the list of templates in the initialization code and supply a suitable template file.
Follow the examples already there and find further documentation with the Shortcode gem.

## Feedback
Welcome.
