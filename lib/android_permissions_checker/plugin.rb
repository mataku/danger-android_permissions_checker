require 'fileutils'

module Danger
  class DangerAndroidPermissionsChecker < Plugin
    def check(apk: nil, permission_list_file: nil)
      if apk.nil? || !File.exist?(apk)
        raise "Can\'t find apk: #{apk}"
      end

      if permission_list_file.nil? || !File.exist?(permission_list_file)
        raise "Can't find permission list file: #{permission_list_file}\n"
      end

      unless system 'which aapt > /dev/null 2>&1'
        raise 'Can\'t find required command: aapt. Set PATH to Android Build-tools.'
      end

      current_permissions = `aapt d permissions #{apk}`.split("\n")
      generated_permissions = File.open(permission_list_file).readlines.map(&:chomp)

      deleted = current_permissions - generated_permissions
      added = generated_permissions - current_permissions
      message = ""
      
      if deleted.length > 0
        message += "Deleted permissions\n"
        deleted.each do |v|
          message += "- #{v}\n"
        end
        message += "\n"
      end

      if added.length > 0
        message += "Added Permissions\n"

        added.each do |v|
          message += "- #{v}\n"
        end
      end

      warn(message) if message
    end
  end
end
