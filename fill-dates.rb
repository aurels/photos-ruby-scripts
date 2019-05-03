require "bundler"

Bundler.require

I18n.available_locales = [:en]

class Photo
  def initialize(root, path)
    @root = root
    @path = path

    trigger_exif!
  end

  def filename
    I18n.transliterate(File.basename(@path))
  end

  def dirname
    I18n.transliterate(File.dirname(@path).split("/").last)
  end

  def relative_path
    @path.gsub(@root, "")
  end

  def date_time_original
    exif.date_time_original
  end

  def new_date_time_original
    if action == :update
      candidate_date_time_original
    else
      nil
    end
  end

  def action
    if date_time_original.nil?
      dirname_compatible? ? :update : :incompatible
    else
      :keep
    end
  end

  def candidate_date_time_original
    if filename_compatible?
      date_parts = filename[0..9].split("-")
      time_parts = filename[11..20].split(".")

      y = date_parts[0].to_i
      m = date_parts[1].to_i
      d = date_parts[2].to_i

      h = time_parts[0].to_i
      n = time_parts[1].to_i
      s = time_parts[2].to_i

      return DateTime.new(y, m, d, h, n, s)
    elsif dirname_compatible?
      parts = dirname.split("-")

      y = parts[0].to_i
      m = [parts[1].to_i, 1].max
      d = [parts[2].to_i, 1].max

      return DateTime.new(y, m, d, 0, 0, 0)
    end
  end

  def filename_compatible?
    filename.match(/\A\d{4}-\d{2}-\d{2} \d{2}.\d{2}.\d{2}/) != nil
  end

  def dirname_compatible?
    dirname.match(/\A\d{4}-(\d{2}|xx)-(\d{2}|xx)/) != nil
  end

  def update_date_time_original!
    return unless action == :update

    exif.date_time_original = new_date_time_original
    exif.comment            = "date set by ruby script"
    exif.save
  end

  private

  def exif
    return @exif if defined?(@exif)

    @exif = MiniExiftool.new(@path)
  end

  def trigger_exif!
    exif
  end
end

opts = Optimist::options do
  opt :path,   "Path of photos dirs",      type: String
  opt :update, "Update dates in EXIF tags"
  opt :verbose, "Update dates in EXIF tags"
end

if opts.path
  paths    = Dir["#{opts.path}/**/*.{jpg,jpe,jpeg,JPG,JPEG,JPE}"]
  progress = ProgressBar.create(title: "Collecting EXIF data", total: paths.size)

  photos = paths.map do |path|
    p = Photo.new(opts.path, path)
    progress.increment

    p
  end

  photos_to_update    = photos.select { |p| p.action == :update }
  incompatible_photos = photos.select { |p| p.action == :incompatible }

  tp((opts[:verbose] ? photos : photos_to_update + incompatible_photos),
    { dirname:                { width: 100, display_name: "Dir"      } },
    { filename:               { width: 100, display_name: "File"     } },
    { date_time_original:     { width: 50,  display_name: "Date"     } },
    { action:                 { width: 30,  display_name: "Action"   } },
    { new_date_time_original: { width: 50,  display_name: "New Date" } }
  )

  puts "#{paths.size} photos found"
  puts "=> #{photos_to_update.size} photos to update"
  puts "=> #{incompatible_photos.size} incompatible photos"

  if opts[:update]
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
