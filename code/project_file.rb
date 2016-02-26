class ProjectFile
  attr_accessor :children, :size, :path

  EXT_MAP =  {
      'xls'  => :xls,
      'xlsx' => :xls,
      'doc'  => :doc,
      'docx' => :doc,
      'zip'  => :zip,
      'txt'  => :txt,
      'pdf'  => :pdf,
      'sql'  => :sql,
  }

  def self.find_by_project_name(name)
    project_files = self.files.all({:prefix => name})
    output_files = Hash.new
    file_lookup = Hash.new 
    root = nil

    project_files.each do |project_file|
      file_lookup[project_file.key] = convert(project_file)
    end

     file_lookup.values.each do |project_file|
      if project_file.parent_name.nil?
        root = project_file
      else
        parent = file_lookup[project_file.parent_name]
        parent.children ||= []
        parent.children  << project_file
      end
     end
    return root
  end

  def self.find_link_by_name(name)
    fog_file = self.files.get(name)
    expiration = Time.now + 60.seconds
    fog_file.url(expiration)
  end

  def self.convert(fog_file)
    file = ProjectFile.new
    file.size = fog_file.content_length
    file.path = fog_file.key
    file.children = nil
    return file
  end

  def self.files
    FOG_STORAGE.directories.get(Settings.aws_bucket).files
  end

  def extension
    ext = self.path[path.rindex(/\./) + 1..-1]
    EXT_MAP[ext]
  end

  def extension_css
    unless extension.nil?
      extension.to_s
    else
      "default"
    end
  end
  
  def file_name
    parent_index = path.rindex(/\//,-2)
    if parent_index.nil?
      path
    else
      path[parent_index +1..-1]
    end
  end

  def parent_name
    parent_index = path.rindex(/\//,-2)
    if parent_index.nil?
      nil
    else
      path[0..parent_index]
    end
  end

  def is_directory?
    not children.nil?
  end

  def str_size
      if size > 1024 * 1024 * 1024
        "%0.0f GB" % (size / (1024 * 1024 * 1024))
      elsif size > 1024 * 1024
        "%0.0f MB" % (size / (1024 * 1024 ))
      else
        "%0.0f KB" % (size / 1024)
      end
  end
end