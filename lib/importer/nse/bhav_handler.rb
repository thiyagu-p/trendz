module Importer
  module Nse
    module BhavHandler
      module ClassMethods
        def model(model_name)
          class_eval do
            define_method :model do
              model_name
            end
          end
        end

        def startdate(date)
          class_eval do
            define_method :startdate do
              date
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

      def parse_bhav_file(file_name, zip_file_name, date)
        Stock.transaction do
          Zip::ZipFile.open("data/#{zip_file_name}") do |zipfile|
            CSV.parse(zipfile.file.read(file_name)) do |columns|
              process_row(columns) if columns.count > 1
            end
          end
          ImportStatus.find_by_source(status_source).update_attributes! data_upto: date
        end
      end

      def status_source
        "ImportStatus::Source::NSE_#{sub_path}_BHAV".constantize
      end

      def import
        start_date = (model.maximum('date') or Date.parse(startdate)) + 1
        begin
          (start_date .. Date.today).each do |date|
            Rails.logger.info "processing #{sub_path} bhav for #{date}"
            file_name, file_path, zip_file_name = file_names(date)
            response = get(file_path)
            unless response.class == Net::HTTPNotFound
              open("data/#{zip_file_name}", 'wb') { |file| file << response.body }
              parse_bhav_file(file_name, zip_file_name, date)
            end
          end
          ImportStatus.completed(status_source)
        rescue => e
          Rails.logger.error "Error importing NSE #{sub_path} bhav #{e.inspect}"
          ImportStatus.failed(status_source)
        end
      end

      def file_names(date)
        month = date.strftime("%b").upcase
        file_name = "#{file_name_prefix}#{date.strftime("%d")}#{month}#{date.year}bhav.csv"
        zip_file_name = "#{file_name}.zip"
        file_path = "/content/historical/#{sub_path}/#{date.year}/#{month}/#{zip_file_name}"
        return file_name, file_path, zip_file_name
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

    end
  end
end