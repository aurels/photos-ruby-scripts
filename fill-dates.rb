require "bundler"
require "./lib/photo"

Bundler.require

opts = Optimist::options do
  opt :path,   "Path of photos dirs",      type: String
  opt :update, "Update dates in EXIF tags"
  opt :verbose, "Update dates in EXIF tags"
end

if opts.path
  paths    = Dir["#{opts.path}/**/*.{jpg,jpe,jpeg}"]
  progress = ProgressBar.create(title: "Collecting EXIF data", total: paths.size)

  photos = paths.map do |path|
    p = Photo.new(opts.path, path)
    progress.increment

    p
  end

  if opts.verbose?
    tp(photos,
      { dirname:                { width: 150, display_name: "Dir"      } },
      { filename:               { width: 200, display_name: "File"     } },
      { date_time_original:     { width: 50,  display_name: "Date"     } },
      { action:                 { width: 30,  display_name: "Action"   } },
      { new_date_time_original: { width: 50,  display_name: "New Date" } }
    )
  end

  photos_to_update    = photos.select { |p| p.action == :update }
  incompatible_photos = photos.select { |p| p.action == :incompatible }

  puts "#{paths.size} photos found"
  puts
  puts "=> #{photos_to_update.size} photos to update"
  puts "=> #{incompatible_photos.size} incompatible photos"

  if opts.update?
    puts

    progress = ProgressBar.create(title: "Updating EXIF data", total: photos_to_update.size)

    photos_to_update.each do |photo|
      photo.update_date_time_original!
      progress.increment
    end
  end
else
  puts "[error] Please provide a path"
end
