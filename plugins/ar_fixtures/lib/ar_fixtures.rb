# Extension to make it easy to read and write data to a file.
class ActiveRecord::Base
  
  # Delete existing data and load fresh from file 
  def self.load_from_file
    self.find_all.each { |old_record| old_record.destroy }

    if connection.respond_to?(:reset_pk_sequence!)
     connection.reset_pk_sequence!(table_name)
    end

    records = YAML::load( File.open( File.expand_path("db/#{table_name}.yml", RAILS_ROOT) ) )
    records.each do |record|
     record_copy = self.new(record.attributes)
     record_copy.id = record.id
     record_copy.save
    end
 
    if connection.respond_to?(:reset_pk_sequence!)
     connection.reset_pk_sequence!(table_name)
    end
  end

  # Writes to db/table_name.yml
  def self.dump_to_file
    write_file(File.expand_path("db/#{table_name}.yml", RAILS_ROOT), self.find(:all).to_yaml)
  end

  # Write a file that can be loaded with fixture :some_table in tests.
  def self.to_fixture
    write_file(File.expand_path("test/fixtures/#{table_name}.yml", RAILS_ROOT), 
        self.find(:all).inject({}) { |hsh, record| 
            hsh.merge(record.id => record.attributes) 
          }.to_yaml)
  end

  def self.write_file(path, content)
    f = File.new(path, "w+")
    f.puts content
    f.close
  end

end
