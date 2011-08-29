module Importer
  module BhavHandler
    module ClassMethods
      def model(model_name)
        class_eval do
          define_method :model do
            model_name
          end
        end
      end

      def sub_path(folder_name)
        class_eval do
          define_method :sub_path do
            folder_name
          end
        end
      end

      def file_name_prefix(prefix)
        class_eval do
          define_method :file_name_prefix do
            prefix
          end
        end
      end
    end

    def parse_bhav_file(file_name, zip_file_name)
      begin
        Stock.transaction do
          Zip::ZipFile.open("data/#{zip_file_name}") do |zipfile|
            CSV.parse(zipfile.file.read(file_name)) do |line|
              process_row(line)
            end
          end
        end
      rescue Zip::ZipError => e
        p e
      end
    end

    def import
      start_date = (model.maximum('date') or Date.parse('31/12/2004')) + 1
      (start_date .. Date.today).each do |date|
        Rails.logger.info "processing #{sub_path} bhav for #{date}"
        month = date.strftime("%b").upcase
        file_name = "#{file_name_prefix}#{date.strftime("%d")}#{month}#{date.year}bhav.csv"
        zip_file_name = "#{file_name}.zip"
        file_path = "/content/historical/#{sub_path}/#{date.year}/#{month}/#{zip_file_name}"
        response = get(file_path)
        next if response.class == Net::HTTPNotFound
        open("data/#{zip_file_name}", 'wb') { |file| file << response.body }
        parse_bhav_file(file_name, zip_file_name)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end