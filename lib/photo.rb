class Photo
  def initialize(root, path)
    @root = root
    @path = path

    trigger_exif!
  end

  def filename
    File.basename(@path)
  end

  def dirname
    File.dirname(@path).split("/").last
  end

  def relative_path
    @path.gsub(@root, "")
  end

  def date_time_original
    exif.date_time_original
  end

  def new_date_time_original
    if action == :update
      dirname_date_time_original
    end
  end

  def action
    if date_time_original.nil?
      dirname_compatible? ? :update : :incompatible
    else
      :keep
    end
  end

  def dirname_date_time_original
    return nil unless dirname_compatible?

    parts = dirname.split("-")

    y = parts[0].to_i

    m = [parts[1].to_i, 1].max
    d = [parts[2].to_i, 1].max

    DateTime.new(y, m, d, 0, 0, 0)
  end

  def dirname_compatible?
    dirname.match(/\A\d{4}-(\d{2}|xx)-(\d{2}|xx)/) != nil
  end

  def update_date_time_original!
    return unless action == :update

    exif.date_time_original = new_date_time_original
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
